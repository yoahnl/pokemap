import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../features/pokemon/domain/pokemon_workspace_models.dart';

import 'package:map_core/map_core_domain.dart';
import 'package:map_core/map_core.dart'
    show ProjectModel3dEntry, Model3dAnimation, resolveScenePlayerAvatarCharacter;

import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/feedback/studio_notice.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_draft_field.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_toggle_row.dart';

import 'scene_actor_action_form.dart';
import 'scene_npc_pose_action_form.dart';
import 'scene_pokemon_gift_moves_editor.dart';
import 'scene_integer_authoring_fields.dart';

part 'scene_action_references.dart';

class SceneActionForm extends StatefulWidget {
  const SceneActionForm({
    super.key,
    required this.project,
    required this.current,
    required this.onApply,
    this.loadMap,
    this.loadMoves,
    this.loadSpecies,
    this.commandCatalog,
  });

  final ProjectManifest project;
  final SceneNodePayload? current;
  final ValueChanged<SceneNodePayload> onApply;
  final Future<MapData> Function(String)? loadMap;
  final Future<Map<String, String>> Function()? loadMoves;
  final Future<List<PokemonSpeciesSummary>> Function()? loadSpecies;
  @visibleForTesting
  final List<NarrativeCommandDescriptor>? commandCatalog;

  @override
  State<SceneActionForm> createState() => _SceneActionFormState();
}

class _SceneActionFormState extends State<SceneActionForm> {
  List<NarrativeCommandDescriptor> get _commands => [
    for (final command
        in widget.commandCatalog ??
            NarrativeCommandCatalog.canonical().commands)
      if (command.isPublishable &&
          (!_is2DPresentationCommand(command.id) ||
              widget.project.settings.dimension == ProjectDimension.twoD) &&
          (!_isActorCommand(command.id) ||
              widget.project.settings.dimension == ProjectDimension.twoD) &&
          (command.id != NarrativeCommandIds.playModelAnimation ||
              widget.project.settings.dimension == ProjectDimension.threeD) &&
          command.backend != NarrativeCommandBackend.dedicatedSceneNode)
        command,
  ];
  final _values = <String, String>{};
  String? _commandId;
  bool _unsupported = false;
  String? _error;
  MapData? _referenceMap;
  String? _referenceMapId;
  String? _referenceError;
  bool _referenceLoading = false;
  int _referenceRequest = 0;
  List<PokemonSpeciesSummary> _species = const [];
  bool _speciesLoading = false;
  String? _speciesError;
  int _speciesRequest = 0;
  bool _giftMovesValid = true;
  bool get _isGift =>
      _commandId == NarrativeCommandIds.givePokemonFromCatalog ||
      _commandId == NarrativeCommandIds.receivePokemonFromCatalog;
  List<String>? get _giftMoves {
    final value = _values['moveIds'];
    return value == null || value.isEmpty
        ? null
        : (jsonDecode(value) as List).cast<String>();
  }

  Future<void> _loadGiftSpecies() async {
    final token = ++_speciesRequest;
    _species = const [];
    _speciesError = null;
    _speciesLoading = false;
    if (!_isGift) return;
    _speciesLoading = true;
    await Future<void>.value();
    try {
      final load = widget.loadSpecies;
      if (load == null) throw StateError('Unavailable');
      final species = await load();
      if (!mounted || token != _speciesRequest) return;
      final unique =
          species.map((entry) => entry.id).toSet().length == species.length;
      if (!unique) throw StateError('Ambiguous');
      setState(
        () => _species = species
            .where(
              (entry) =>
                  entry.enabled &&
                  entry.isBaseForm &&
                  entry.baseFormId.isNotEmpty &&
                  entry.formIds.contains(entry.baseFormId),
            )
            .toList(),
      );
    } on Object {
      if (!mounted || token != _speciesRequest) return;
      setState(
        () => _speciesError = 'Catalogue des Pokémon indisponible ou ambigu. Les références enregistrées sont conservées.',
      );
    } finally {
      if (mounted && token == _speciesRequest) {
        setState(() => _speciesLoading = false);
      }
    }
  }
  void _refreshReferences(VoidCallback changed) => setState(changed);

  NarrativeCommandDescriptor? get _command =>
      _commands.where((command) => command.id == _commandId).firstOrNull;

  bool _is2DPresentationCommand(String? id) =>
      id == NarrativeCommandIds.setNpcPose ||
      id == NarrativeCommandIds.setPropState ||
      id == NarrativeCommandIds.whiteOut ||
      id == NarrativeCommandIds.waitForActorRoutes ||
      id == NarrativeCommandIds.wait ||
      id == NarrativeCommandIds.worldTone ||
      id == NarrativeCommandIds.playSoundEffect ||
      id == NarrativeCommandIds.playMusicEffect ||
      id == NarrativeCommandIds.sceneMusic;

  bool _isActorCommand(String? id) =>
      id == NarrativeCommandIds.actorRoute ||
      id == NarrativeCommandIds.actorVisibility;

  @override
  void initState() {
    super.initState();
    _readCurrent();
  }

  @override
  void didUpdateWidget(SceneActionForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isGift &&
        _giftMoves != null &&
        (oldWidget.loadMoves != widget.loadMoves ||
            oldWidget.project != widget.project)) {
      _giftMovesValid = false;
    }
    if (oldWidget.current != widget.current ||
        oldWidget.commandCatalog != widget.commandCatalog) {
      _readCurrent();
    }
    if (oldWidget.loadMap != widget.loadMap ||
        oldWidget.project != widget.project ||
        oldWidget.loadSpecies != widget.loadSpecies) {
      _loadReferenceMap();
      _loadGiftSpecies();
    }
  }

  void _readCurrent() {
    _values.clear();
    _error = null;
    _commandId = null;
    final current = widget.current;
    _unsupported = current != null;
    if (current is! SceneActionPayload) {
      _loadReferenceMap();
      _loadGiftSpecies();
      return;
    }
    final data =
        current.consequence?.toJson() ?? current.interactiveCommand?.toJson();
    _commandId =
        current.consequence?.kind.name ?? current.interactiveCommand?.kind.name;
    if (_command == null || data == null) {
      _commandId = null;
      _loadReferenceMap();
      _loadGiftSpecies();
      return;
    }
    if (_isActorCommand(_commandId)) {
      _unsupported = false;
      _loadReferenceMap();
      _loadGiftSpecies();
      return;
    }
    for (final parameter in _command!.parameters) {
      final presentation = data['presentation'];
      final interruption = data['bgmInterruption'];
      final value = _commandId == NarrativeCommandIds.warp && presentation is Map
          ? parameter.id == 'presentationMode' ? presentation['mode']
              : data[parameter.id] ?? presentation[parameter.id]
          : _commandId == NarrativeCommandIds.playMusicEffect && interruption is Map
          ? data[parameter.id] ?? interruption[parameter.id]
          : isIntegerSceneCommand(_commandId) ? integerSceneStoredParameter(data, parameter.id) : data[parameter.id];
      if (value is String || value is num || value is bool) {
        _values[parameter.id] = '$value';
      } else if (value is List && (parameter.id == 'moveIds' || parameter.id == 'propIds' || parameter.id == 'factIds')) {
        _values[parameter.id] = jsonEncode(value);
      }
    }
    if (data['mapId'] != null && data['entityId'] != null) {
      _values['npcRef'] = '${data['mapId']}::${data['entityId']}';
    }
    try {
      final rebuilt = _buildPayload();
      _unsupported = rebuilt != current;
    } catch (_) {
      _unsupported = true;
    }
    if (_unsupported) _commandId = null;
    _giftMovesValid = !_isGift || _giftMoves == null;
    _loadReferenceMap();
    _loadGiftSpecies();
  }

  SceneNodePayload _buildPayload() {
    var built = buildScenePayloadForNarrativeCommand(
      commandId: _commandId!,
      parameters: _values,
    );
    final original = widget.current;
    if (built is SceneActionPayload && original is SceneActionPayload) {
      final fresh = built.interactiveCommand, previous = original.interactiveCommand;
      if (fresh is SceneInputIntegerToFactInteractiveCommand && previous is SceneInputIntegerToFactInteractiveCommand) {
        built = SceneActionPayload.interactive(SceneInteractiveCommand.fromJson({...fresh.toJson(),
          'prompt': {...previous.prompt.toJson(), 'fallbackText': fresh.prompt.fallbackText}}));
      }
      if (fresh is SceneTryPayMoneyInteractiveCommand && previous is SceneTryPayMoneyInteractiveCommand && fresh.confirmationPrompt != null && previous.confirmationPrompt != null) {
        built = SceneActionPayload.interactive(SceneInteractiveCommand.fromJson({...fresh.toJson(),
          'confirmationPrompt': {...previous.confirmationPrompt!.toJson(), 'fallbackText': fresh.confirmationPrompt!.fallbackText}}));
      }
    }
    if (built is SceneActionPayload && original is SceneActionPayload) {
      final avatar = built.consequence;
      final originalAvatar = original.consequence;
      return SceneActionPayload(
        actionKind: original.actionKind,
        parameters: original.parameters,
        consequence: avatar is SceneSetPlayerAvatarConsequence &&
                originalAvatar is SceneSetPlayerAvatarConsequence
            ? SceneConsequence.setPlayerAvatar(
                characterId: avatar.characterId,
                label: originalAvatar.label,
                notes: originalAvatar.notes,
              )
            : built.consequence,
        interactiveCommand: built.interactiveCommand,
        preSessionInteraction: built.preSessionInteraction,
      );
    }
    return built;
  }

  void _choose(String commandId) => setState(() {
    _commandId = commandId;
    _error = null;
    _values.clear();
    for (final parameter in _command!.parameters) {
      if (parameter.kind == NarrativeCommandParameterKind.boolean &&
          parameter.required) {
        _values[parameter.id] = 'true';
      } else if (parameter.kind == NarrativeCommandParameterKind.integer &&
          parameter.required) {
        _values[parameter.id] = '1';
      }
    }
    if (isIntegerSceneCommand(commandId)) {
      _values.addAll({'operandSource': 'literal', 'operandValue': '0', 'operation': commandId == NarrativeCommandIds.adjustMoney ? 'add' : 'assign',
        'minimum': '0', 'maximum': '999', 'digits': '3', 'randomMinimum': '0', 'randomMaximum': '4',
        'factIds': '[]', 'zeroDivisorPolicy': 'reject', 'boundaryPolicy': 'clamp', 'cancellationPolicy': 'leaveUnchanged'});
    }
    _giftMovesValid = true;
    if (commandId == NarrativeCommandIds.receivePokemonFromCatalog) {
      _values['nicknamePolicy'] = 'offer';
      _values['nicknameMaxGraphemes'] = '12';
      _values['pokedexPresentationPolicy'] = 'never';
    }
    if (commandId == NarrativeCommandIds.sceneMusic) {
      _values['operation'] = 'play';
      _values['volume'] = '1';
    }
    if (commandId == NarrativeCommandIds.playModelAnimation) {
      _values['speed'] = '1';
    } else if (commandId == NarrativeCommandIds.setPropState) {
      _values['durationMs'] = '350';
      _values['state'] = 'open';
      _values['propIds'] = '[]';
    } else if (commandId == NarrativeCommandIds.wait) {
      _values['durationMs'] = '0';
    } else if (commandId == NarrativeCommandIds.worldTone) {
      for (final id in ['red', 'green', 'blue', 'gray', 'durationMs']) {
        _values[id] = '0';
      }
    } else if (commandId == NarrativeCommandIds.playSoundEffect ||
        commandId == NarrativeCommandIds.playMusicEffect) {
      _values['volume'] = '1';
      if (commandId == NarrativeCommandIds.playMusicEffect) {
        _values['fadeOutMs'] = '0';
        _values['fadeInMs'] = '0';
      }
    }
    _loadReferenceMap();
    _loadGiftSpecies();
  });

  bool get _valid {
    final command = _command;
    if (command == null) return false;
    if (command.id == NarrativeCommandIds.setPropState) {
      if (_referenceLoading || _referenceError != null || _referenceMap == null) return false;
      try {
        final built = _buildPayload() as SceneActionPayload;
        final command = built.interactiveCommand! as SceneSetPropStateInteractiveCommand;
        if (command.propIds.any((id) => !_movingProps.containsKey(id))) return false;
      } catch (_) {
        return false;
      }
    }
    if (_isGift &&
        (_speciesLoading || _speciesError != null || !_giftMovesValid)) {
      return false;
    }
    for (final parameter in command.parameters) {
      if (!_warpFieldVisible(parameter)) continue;
      final value = _values[parameter.id];
      if (parameter.kind == NarrativeCommandParameterKind.integerFacts) {
        try {
          final ids = (jsonDecode(value ?? '[]') as List).cast<String>();
          if (ids.isEmpty || ids.toSet().length != ids.length || ids.any((id) => !_options(parameter.kind).containsKey(id))) return false;
        } catch (_) { return false; }
        continue;
      }
      if (parameter.kind == NarrativeCommandParameterKind.movingProps) continue;
      if (value == null || value.trim().isEmpty) {
        if (parameter.required) return false;
        continue;
      }
      if (parameter.kind == NarrativeCommandParameterKind.integer) {
        if (int.tryParse(value) == null) return false;
      } else if (parameter.kind == NarrativeCommandParameterKind.number) {
        final number = double.tryParse(value);
        if (number == null || !number.isFinite) return false;
      } else if (parameter.kind != NarrativeCommandParameterKind.text &&
          parameter.kind != NarrativeCommandParameterKind.boolean &&
          !_options(parameter.kind).containsKey(value)) {
        return false;
      }
    }
    if (command.id == NarrativeCommandIds.playModelAnimation) {
      final rawSpeed = _values['speed']?.trim();
      final speed = double.tryParse(
        rawSpeed == null || rawSpeed.isEmpty ? '1' : rawSpeed,
      );
      if (speed == null || !speed.isFinite || speed <= 0 || speed > 16) {
        return false;
      }
    }
    if (_isGift || isIntegerSceneCommand(command.id) ||
        command.id == NarrativeCommandIds.warp ||
        command.id == NarrativeCommandIds.wait ||
        command.id == NarrativeCommandIds.worldTone ||
        command.id == NarrativeCommandIds.playSoundEffect ||
        command.id == NarrativeCommandIds.playMusicEffect ||
        command.id == NarrativeCommandIds.sceneMusic) {
      try {
        final payload = _buildPayload();
        if (payload is SceneActionPayload) {
          final command = payload.interactiveCommand;
          if (command is SceneWarpInteractiveCommand && command.presentation != null &&
              diagnoseInteractiveCommand(command: command, project: widget.project).isNotEmpty) {
            return false;
          }
        }
      } catch (_) {
        return false;
      }
    }
    return true;
  }

  static const _warpPresentationFields = {'presentationMode', 'illustrationElementId',
    'fadeOutMs', 'transferDelayMs', 'revealMs', 'illustrationHoldMs', 'illustrationFadeMs'};

  bool _warpFieldVisible(NarrativeCommandParameterDescriptor parameter) {
    if (isIntegerSceneCommand(_commandId)) return integerSceneParameterVisible(parameter.id, _values);
    if (_commandId == NarrativeCommandIds.sceneMusic) {
      return switch (parameter.id) {
        'mediaAssetId' || 'volume' => _values['operation'] == 'play',
        'durationMs' => _values['operation'] == 'fadeOut',
        _ => true,
      };
    }
    if (_commandId != NarrativeCommandIds.warp) return true;
    final mode = _values['presentationMode'];
    final active = mode != null && mode.isNotEmpty;
    if (parameter.id == 'transition') return !active;
    if (!_warpPresentationFields.contains(parameter.id)) return true;
    if (widget.project.settings.dimension != ProjectDimension.twoD) return false;
    if (parameter.id == 'presentationMode') return true;
    if (!active) return false;
    if (const {'illustrationElementId', 'illustrationHoldMs', 'illustrationFadeMs'}.contains(parameter.id)) {
      return mode == 'illustrated' || mode == 'caveEntrance';
    }
    return true;
  }

  Map<String, String> _warpIllustrations() {
    final result = <String, String>{};
    for (final element in widget.project.elements) {
      try {
        resolveSceneWarpPresentationVisual(SceneWarpPresentation(
          mode: SceneWarpPresentationMode.illustrated, illustrationElementId: element.id), widget.project);
        result[element.id] = element.name;
      } catch (_) {}
    }
    return result;
  }

  Map<String, String> _musicMediaOptions() {
    final counts = <String, int>{};
    for (final media in widget.project.cinematicMediaAssets) {
      counts[media.id] = (counts[media.id] ?? 0) + 1;
    }
    return {
      for (final media in widget.project.cinematicMediaAssets)
        if (counts[media.id] == 1 &&
            media.kind == CinematicMediaAssetKind.music)
          media.id: media.label,
    };
  }

  Map<String, String> _soundMediaOptions() {
    final counts = <String, int>{};
    for (final media in widget.project.cinematicMediaAssets) {
      counts[media.id] = (counts[media.id] ?? 0) + 1;
    }
    return {
      for (final media in widget.project.cinematicMediaAssets)
        if (counts[media.id] == 1 &&
            media.kind == CinematicMediaAssetKind.sound &&
            !media.loopByDefault)
          media.id: media.label,
    };
  }

  Map<String, String> _playerAvatarOptions() {
    final options = <String, String>{};
    for (final character in widget.project.characters) {
      try {
        final avatar = resolveScenePlayerAvatarCharacter(
          widget.project,
          character.id,
        );
        options[avatar.id] = avatar.name;
      } on FormatException {
        continue;
      }
    }
    return options;
  }

  Map<String, String> _options(
    NarrativeCommandParameterKind kind,
  ) => integerSceneOptions(kind, project: widget.project, commandId: _commandId) ?? switch (kind) {
    NarrativeCommandParameterKind.character => _playerAvatarOptions(),
    NarrativeCommandParameterKind.species => {
      for (final species in _species) species.id: species.name,
    },
    NarrativeCommandParameterKind.speciesForm => {
      for (final species in _species)
        if (species.id == _values['speciesId'])
          species.baseFormId: species.baseFormId == 'base'
              ? 'Forme principale'
              : species.baseFormId,
    },
    NarrativeCommandParameterKind.pokemonGiftNicknamePolicy => const {
      'offer': 'Proposer un surnom',
      'disabled': 'Garder le nom de l’espèce',
    },
    NarrativeCommandParameterKind.pokemonGiftPokedexPolicy => const {
      'never': 'Ne pas présenter',
      'whenNewAndPokedexVisible': 'Si nouveau et Pokédex disponible',
    },
    NarrativeCommandParameterKind.fact => {
      for (final fact in widget.project.facts)
        if (fact.valueKind == NarrativeValueKind.boolean) fact.id: fact.label,
    },
    NarrativeCommandParameterKind.event => {
      for (final event
          in widget.project.eventRegistry?.records ?? <NarrativeEventRecord>[])
        event.id: event.definitionOrNull?.name ?? event.draftOrNull!.name,
    },
    NarrativeCommandParameterKind.storyStep => {
      for (final story in widget.project.storylines)
        for (final chapter in story.chapters)
          for (final step in chapter.steps)
            step.id: '${story.title} · ${step.title}',
    },
    NarrativeCommandParameterKind.map => {
      for (final map in widget.project.maps)
        if (_commandId != NarrativeCommandIds.waitForActorRoutes ||
            (map.id.isNotEmpty &&
                map.id.trim() == map.id &&
                widget.project.maps
                        .where((entry) => entry.id == map.id)
                        .length ==
                    1))
          map.id: map.name,
    },
    NarrativeCommandParameterKind.warp => _warpPoints,
    NarrativeCommandParameterKind.movingPropState => const {'closed': 'Fermé', 'open': 'Ouvert'},
    NarrativeCommandParameterKind.characterDirection =>
      _commandId == NarrativeCommandIds.warp
          ? const {
              'north': 'Nord',
              'south': 'Sud',
              'east': 'Est',
              'west': 'Ouest',
            }
          : const {},
    NarrativeCommandParameterKind.warpPresentationMode => const {
      '': 'Transition habituelle', 'fade': 'Fondu noir',
      'illustrated': 'Illustration du lieu', 'caveEntrance': 'Entrée de grotte', 'caveExit': 'Sortie de grotte',
    },
    NarrativeCommandParameterKind.visualElementReference => _warpIllustrations(),
    NarrativeCommandParameterKind.warpTransition => const {
      'mapDefault': 'Transition de la carte',
      'none': 'Sans transition',
    },
    NarrativeCommandParameterKind.modelInstance => _modelInstances,
    NarrativeCommandParameterKind.modelAnimation => _modelAnimations,
    NarrativeCommandParameterKind.soundMediaReference => _soundMediaOptions(),
    NarrativeCommandParameterKind.musicMediaReference => _musicMediaOptions(),
    NarrativeCommandParameterKind.sceneMusicOperation => const {
      'play': 'Jouer une musique en boucle',
      'restore': 'Restaurer l’ambiance',
      'fadeOut': 'Fondre la musique',
    },
    NarrativeCommandParameterKind.shop => {
      for (final shop in widget.project.shops) shop.id: shop.label,
    },
    NarrativeCommandParameterKind.badge => {
      for (final badge in widget.project.badges) badge.id: badge.label,
    },
    NarrativeCommandParameterKind.fieldAbility => const {
      'fly': 'Vol',
      'surf': 'Surf',
      'cut': 'Coupe',
      'strength': 'Force',
      'flash': 'Flash',
      'rock_smash': 'Éclate-Roc',
      'waterfall': 'Cascade',
      'whirlpool': 'Tourbillon',
      'dive': 'Plongée',
    },
    NarrativeCommandParameterKind.completionOutcome => const {
      'completed': 'Partie terminée',
      'victory': 'Victoire',
      'alternateEnding': 'Fin alternative',
    },
    NarrativeCommandParameterKind.postGamePolicy => const {
      'continueGame': 'Continuer après la fin',
      'returnToTitle': 'Retourner au titre',
      'returnToHub': 'Retourner au Hub',
    },
    NarrativeCommandParameterKind.pauseMenuAction => {
      for (final entry in ProjectPauseActionId.values) entry.name: entry.name,
    },
    _ => const {},
  };

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (_unsupported)
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: StudioNotice(
            'Cette action conserve des paramètres avancés. Choisir une autre commande puis appliquer la remplacera explicitement.',
          ),
        ),
      StudioSelect(
        label: 'Commande',
        value: _commandId,
        options: {for (final command in _commands) command.id: command.label},
        onChanged: _commands.isEmpty ? null : _choose,
      ),
      if (_commands.isEmpty) const StudioNotice('Aucune commande disponible.'),
      if (_commandId == NarrativeCommandIds.whiteOut)
        const StudioNotice('À la fin réussie de la Scene, l’équipe est soignée, la pénalité de défaite est appliquée et le joueur revient au point de reprise. Une seule récupération par Scene.'),
      if (_isGift && _speciesLoading)
        const StudioNotice('Chargement des Pokémon…'),
      if (_isGift && _speciesError != null)
        StudioNotice(_speciesError!, isError: true),
      if (_referenceLoading)
        StudioNotice(
          _commandId == NarrativeCommandIds.warp
              ? 'Chargement des points d’arrivée…'
              : 'Chargement des décors de la carte…',
        ),
      if (_referenceError != null) ...[
        StudioNotice(_referenceError!, isError: true),
        StudioButton(
          label: 'Recharger la carte',
          secondary: true,
          onPressed: () => setState(_loadReferenceMap),
        ),
      ],
      if (_isActorCommand(_commandId))
        SceneActorActionForm(
          key: ValueKey(_commandId),
          project: widget.project,
          commandId: _commandId!,
          current: widget.current is SceneActionPayload
              ? widget.current as SceneActionPayload
              : null,
          loadMap: widget.loadMap,
          onApply: widget.onApply,
        ),
      if (_commandId == NarrativeCommandIds.setNpcPose)
        SceneNpcPoseActionForm(project: widget.project,
          current: widget.current is SceneActionPayload ? widget.current as SceneActionPayload : null,
          loadMap: widget.loadMap, onApply: widget.onApply),
      if (_commandId == NarrativeCommandIds.sceneMusic)
        const StudioNotice(
          'La musique tourne en boucle pendant cette scène. L’ambiance précédente est restaurée à la fin ; les combats gardent la priorité.',
        ),
      if (!_isActorCommand(_commandId) && _commandId != NarrativeCommandIds.setNpcPose) ...[
        for (final parameter
            in _command?.parameters ?? <NarrativeCommandParameterDescriptor>[])
          if (_warpFieldVisible(parameter)) Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _field(parameter),
          ),
        if (_error != null) StudioNotice(_error!, isError: true),
        const SizedBox(height: 12),
        StudioButton(
          label: widget.current == null
              ? 'Ajouter l’action'
              : 'Appliquer l’action',
          onPressed: !_valid
              ? null
              : () {
                  try {
                    widget.onApply(_buildPayload());
                  } catch (error) {
                    setState(
                      () => _error = 'Paramètres incompatibles : $error',
                    );
                  }
                },
        ),
      ],
    ],
  );

  Widget _field(NarrativeCommandParameterDescriptor parameter) {
    if (_isGift && parameter.id == 'moveIds') {
      return ScenePokemonGiftMovesEditor(
        key: ValueKey('gift-moves-$_commandId'),
        value: _giftMoves,
        loadMoves: widget.loadMoves,
        catalogueScope: widget.project,
        onChanged: (value) => setState(() {
          if (value == null) {
            _values.remove('moveIds');
          } else {
            _values['moveIds'] = jsonEncode(value);
          }
        }),
        onValidityChanged: (value) {
          if (mounted && _giftMovesValid != value) {
            setState(() => _giftMovesValid = value);
          }
        },
      );
    }
    void changed(String value) => setState(() {
      _values[parameter.id] = value;
      _error = null;
      if (_commandId == NarrativeCommandIds.sceneMusic &&
          parameter.id == 'operation') {
        for (final key in ['mediaAssetId', 'volume', 'durationMs']) {
          _values.remove(key);
        }
        if (value == 'play') _values['volume'] = '1';
        if (value == 'fadeOut') _values['durationMs'] = '1000';
      }
      if (_commandId == NarrativeCommandIds.warp && parameter.id == 'presentationMode') {
        if (value != 'illustrated' && value != 'caveEntrance') {
          for (final key in ['illustrationElementId', 'illustrationHoldMs', 'illustrationFadeMs']) { _values.remove(key); }
        }
        if (value.isEmpty) {
          for (final key in ['fadeOutMs', 'transferDelayMs', 'revealMs']) { _values.remove(key); }
        }
      }
      if (_isGift && parameter.id == 'speciesId') {
        _values['formId'] =
            _species
                .where((species) => species.id == value)
                .firstOrNull
                ?.baseFormId ??
            '';
      }
      if (parameter.id == 'destinationMapId' &&
          _commandId == NarrativeCommandIds.warp) {
        _values.remove('warpId');
        _loadReferenceMap();
      } else if (parameter.id == 'mapId') {
        _values.remove('instanceId');
        _values.remove('animationIndex');
        if (_commandId == NarrativeCommandIds.setPropState) _values['propIds'] = '[]';
        _loadReferenceMap();
      } else if (parameter.id == 'instanceId') {
        _values.remove('animationIndex');
      }
    });
    if (parameter.kind == NarrativeCommandParameterKind.warpPresentationMode) {
      return StudioSelect(label: parameter.label, value: _values[parameter.id] ?? '',
        options: _options(parameter.kind), onChanged: changed);
    }
    if (_commandId == NarrativeCommandIds.warp &&
        parameter.id == 'arrivalFacing') {
      return StudioSelect(
        label: parameter.label,
        value: _values[parameter.id] ?? '',
        options: {'': 'Conserver la direction', ..._options(parameter.kind)},
        onChanged: changed,
      );
    }
    if (_commandId == NarrativeCommandIds.warp &&
        parameter.id == 'transition') {
      return StudioSelect(
        label: parameter.label,
        value: _values[parameter.id] ?? 'mapDefault',
        options: _options(parameter.kind),
        onChanged: changed,
      );
    }
    if (parameter.id == 'blocksMovementAfter' &&
        _commandId == NarrativeCommandIds.playModelAnimation) {
      return StudioSelect(
        label: parameter.label,
        value: _values[parameter.id] ?? '',
        options: const {
          '': 'Conserver le passage actuel',
          'false': 'Laisser passer',
          'true': 'Bloquer le passage',
        },
        onChanged: changed,
      );
    }
    if (parameter.kind == NarrativeCommandParameterKind.integerFacts) {
      final selected = <String>{};
      try { selected.addAll((jsonDecode(_values[parameter.id] ?? '[]') as List).cast<String>()); } catch (_) {}
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(parameter.label),
        for (final entry in _options(parameter.kind).entries)
          StudioToggleRow(key: ValueKey('scene-integer-fact-${entry.key}'), label: entry.value,
            value: selected.contains(entry.key), onChanged: (value) {
              final next = {...selected}; value ? next.add(entry.key) : next.remove(entry.key);
              changed(jsonEncode(next.toList()));
            }),
      ]);
    }
    if (parameter.kind == NarrativeCommandParameterKind.movingProps) {
      final selected = <String>{};
      try { selected.addAll((jsonDecode(_values['propIds'] ?? '[]') as List).cast<String>()); } catch (_) {}
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(parameter.label),
        if (_referenceLoading) const StudioNotice('Chargement des décors mobiles…'),
        if (_referenceError != null) StudioNotice(_referenceError!),
        if (!_referenceLoading && _referenceError == null && _movingProps.isEmpty)
          const StudioNotice('Configurez les décors mobiles dans les propriétés des décors de cette carte.'),
        for (final missing in selected.difference(_movingProps.keys.toSet())) ...[
          const StudioNotice('Un décor sélectionné n’existe plus. Retirez-le de la sélection.'),
          StudioButton(label: 'Retirer la référence absente', secondary: true,
              onPressed: () => changed(jsonEncode(selected.difference({missing}).toList()))),
        ],
        for (final entry in _movingProps.entries)
          StudioToggleRow(key: ValueKey('scene-prop-${entry.key}'), label: entry.value,
            value: selected.contains(entry.key), onChanged: (value) {
              final next = {...selected};
              value ? next.add(entry.key) : next.remove(entry.key);
              changed(jsonEncode(next.toList()));
            }),
      ]);
    }
    if (parameter.kind == NarrativeCommandParameterKind.boolean) {
      return StudioToggleRow(
        label: parameter.label,
        value: _values[parameter.id] == 'true',
        onChanged: (value) => changed('$value'),
      );
    }
    if (parameter.kind == NarrativeCommandParameterKind.integer ||
        parameter.kind == NarrativeCommandParameterKind.number ||
        parameter.kind == NarrativeCommandParameterKind.text) {
      final presentation =
          _commandId == NarrativeCommandIds.wait ||
          _commandId == NarrativeCommandIds.worldTone ||
          _commandId == NarrativeCommandIds.playSoundEffect ||
          _commandId == NarrativeCommandIds.playMusicEffect ||
          _commandId == NarrativeCommandIds.sceneMusic;
      return StudioDraftField(
        key: ValueKey('action-$_commandId-${parameter.id}'),
        label: parameter.label,
        value: _values[parameter.id] ?? '',
        onChanged: changed,
        helperText: presentation ? _presentationFieldHelp(parameter.id) : null,
        errorText: presentation ? _presentationFieldError(parameter.id) : null,
        keyboardType: parameter.kind == NarrativeCommandParameterKind.number
            ? const TextInputType.numberWithOptions(decimal: true, signed: true)
            : presentation &&
                  parameter.kind == NarrativeCommandParameterKind.integer
            ? TextInputType.number
            : null,
      );
    }
    final options = _options(parameter.kind);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSelect(
          label: parameter.label,
          value: _values[parameter.id],
          options: options,
          onChanged: options.isEmpty ? null : changed,
        ),
        if (options.isEmpty)
          StudioNotice(
            'Aucune référence ${parameter.label.toLowerCase()} disponible dans ce contexte. Le contenu existant reste conservé.',
          ),
      ],
    );
  }

  String _presentationFieldHelp(String id) => switch (id) {
    'durationMs' =>
      _commandId == NarrativeCommandIds.sceneMusic
          ? 'Millisecondes entières, de 0 à 60000.'
          : 'Millisecondes entières, de 0 à 2147483647.',
    'volume' => 'Entre 0 et 1.',
    'fadeOutMs' || 'fadeInMs' => 'Millisecondes entières, de 0 à 60000.',
    'gray' => 'Entre 0 et 255.',
    _ => 'Entre -255 et 255.',
  };

  String? _presentationFieldError(String id) {
    final raw = _values[id] ?? '';
    if (raw.trim().isEmpty) return 'Valeur requise.';
    if (id == 'fadeOutMs' || id == 'fadeInMs') {
      final duration = int.tryParse(raw);
      return duration == null || duration < 0 || duration > 60000
          ? 'Saisir un entier entre 0 et 60000.'
          : null;
    }
    if (id == 'durationMs') {
      final duration = int.tryParse(raw);
      return duration == null ||
              duration < 0 ||
              duration >
                  (_commandId == NarrativeCommandIds.sceneMusic
                      ? 60000
                      : 0x7fffffff)
          ? (_commandId == NarrativeCommandIds.sceneMusic
                ? 'Saisir un entier entre 0 et 60000.'
                : 'Saisir un entier entre 0 et 2147483647.')
          : null;
    }
    final value = double.tryParse(raw);
    final minimum = id == 'volume' || id == 'gray' ? 0 : -255;
    final maximum = id == 'volume' ? 1 : 255;
    return value == null ||
            !value.isFinite ||
            value < minimum ||
            value > maximum
        ? 'Saisir un nombre fini. ${_presentationFieldHelp(id)}'
        : null;
  }
}
