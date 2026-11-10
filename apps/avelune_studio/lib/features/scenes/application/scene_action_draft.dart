import 'dart:convert';
import 'dart:math';

import 'package:map_core/map_core_domain.dart';
import 'package:map_core/map_core.dart' show resolveScenePlayerAvatarCharacter;

import '../../pokemon/domain/pokemon_workspace_models.dart';
import 'scene_action_references.dart';
import 'scene_action_payload.dart';
import 'scene_integer_authoring_fields.dart';

class SceneActionDraft {
  SceneActionDraft({
    required this.project,
    required this.changed,
    this.current,
    this.loadMap,
    this.loadMoves,
    this.loadItems,
    this.loadSpecies,
    this.commandCatalog,
  }) {
    _readCurrent();
  }

  ProjectManifest project;
  SceneNodePayload? current;
  Future<MapData> Function(String)? loadMap;
  Future<Map<String, String>> Function()? loadMoves;
  Future<Map<String, String>> Function()? loadItems;
  Future<List<PokemonSpeciesSummary>> Function()? loadSpecies;
  List<NarrativeCommandDescriptor>? commandCatalog;
  final void Function() changed;
  bool _disposed = false;

  void _update(void Function() update) {
    if (_disposed) return;
    update();
    changed();
  }

  void configure({
    required ProjectManifest project,
    required SceneNodePayload? current,
    required Future<MapData> Function(String)? loadMap,
    required Future<Map<String, String>> Function()? loadMoves,
    required Future<Map<String, String>> Function()? loadItems,
    required Future<List<PokemonSpeciesSummary>> Function()? loadSpecies,
    required List<NarrativeCommandDescriptor>? commandCatalog,
  }) {
    final previousProject = this.project;
    final previousCurrent = this.current;
    final previousMap = this.loadMap;
    final previousMoves = this.loadMoves;
    final previousItems = this.loadItems;
    final previousSpecies = this.loadSpecies;
    final previousCatalog = this.commandCatalog;
    this.project = project;
    this.current = current;
    this.loadMap = loadMap;
    this.loadMoves = loadMoves;
    this.loadItems = loadItems;
    this.loadSpecies = loadSpecies;
    this.commandCatalog = commandCatalog;
    if (isGift &&
        giftMoves != null &&
        (previousMoves != loadMoves || previousProject != project)) {
      giftMovesValid = false;
    }
    if (previousCurrent != current || previousCatalog != commandCatalog) {
      _readCurrent();
    }
    if (previousItems != loadItems || previousProject != project) _loadItems();
    if (previousMap != loadMap ||
        previousProject != project ||
        previousSpecies != loadSpecies) {
      loadReferenceMap();
      _loadGiftSpecies();
    }
  }

  void dispose() {
    _disposed = true;
    _references.dispose();
  }

  void loadReferenceMap() {
    _references.load(
      project: project,
      commandId: commandId,
      parameters: values,
      loadMap: loadMap,
    );
  }

  Map<String, String> get _warpPoints => _references.warpPoints;
  Map<String, String> get movingProps => _references.movingProps;
  Map<String, String> get _modelInstances => _references.modelInstances;
  Map<String, String> get _modelAnimations =>
      _references.modelAnimations(values['instanceId']);

  void setGiftMoves(List<String>? moves) => _update(() {
    if (moves == null) {
      values.remove('moveIds');
    } else {
      values['moveIds'] = jsonEncode(moves);
    }
  });

  void setGiftMovesValid(bool valid) {
    if (giftMovesValid != valid) _update(() => giftMovesValid = valid);
  }

  List<NarrativeCommandDescriptor> get commands => [
    for (final command
        in commandCatalog ?? NarrativeCommandCatalog.canonical().commands)
      if (command.isPublishable &&
          (!_is2DPresentationCommand(command.id) ||
              project.settings.dimension == ProjectDimension.twoD) &&
          (!isActorCommand(command.id) ||
              project.settings.dimension == ProjectDimension.twoD) &&
          (command.id != NarrativeCommandIds.playModelAnimation ||
              project.settings.dimension == ProjectDimension.threeD) &&
          command.backend != NarrativeCommandBackend.dedicatedSceneNode)
        command,
  ];
  final values = <String, String>{};
  String? commandId;
  bool unsupported = false;
  String? error;
  late final _references = SceneActionReferences(
    project: project,
    changed: changed,
  );
  MapData? get referenceMap => _references.map;
  String? get referenceError => _references.error;
  bool get referenceLoading => _references.loading;
  List<PokemonSpeciesSummary> species = const [];
  bool speciesLoading = false;
  String? speciesError;
  int _speciesRequest = 0;
  Map<String, String> _items = const {};
  String? itemsError;
  bool itemsLoading = false;
  int _itemsRequest = 0;
  Future<void> _loadItems() async {
    final token = ++_itemsRequest;
    _items = const {};
    itemsError = null;
    itemsLoading = false;
    if (!(command?.parameters.any(
          (field) => field.kind == NarrativeCommandParameterKind.item,
        ) ??
        false)) {
      return;
    }
    itemsLoading = true;
    try {
      final load = loadItems;
      if (load == null) throw StateError('Unavailable');
      final items = await load();
      if (_disposed || token != _itemsRequest) return;
      _update(() => _items = Map.unmodifiable(items));
    } on Object {
      if (_disposed || token != _itemsRequest) return;
      _update(
        () => itemsError = 'Catalogue des objets indisponible. La récompense enregistrée est conservée.',
      );
    } finally {
      if (!_disposed && token == _itemsRequest) {
        _update(() => itemsLoading = false);
      }
    }
  }

  bool giftMovesValid = true;
  bool get isGift =>
      commandId == NarrativeCommandIds.givePokemonFromCatalog ||
      commandId == NarrativeCommandIds.receivePokemonFromCatalog;
  List<String>? get giftMoves {
    final value = values['moveIds'];
    return value == null || value.isEmpty
        ? null
        : (jsonDecode(value) as List).cast<String>();
  }

  Future<void> _loadGiftSpecies() async {
    final token = ++_speciesRequest;
    species = const [];
    speciesError = null;
    speciesLoading = false;
    if (!isGift) return;
    speciesLoading = true;
    await Future<void>.value();
    try {
      final load = loadSpecies;
      if (load == null) throw StateError('Unavailable');
      final species = await load();
      if (_disposed || token != _speciesRequest) return;
      final unique =
          species.map((entry) => entry.id).toSet().length == species.length;
      if (!unique) throw StateError('Ambiguous');
      _update(
        () => this.species = species
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
      if (_disposed || token != _speciesRequest) return;
      _update(
        () => speciesError = 'Catalogue des Pokémon indisponible ou ambigu. Les références enregistrées sont conservées.',
      );
    } finally {
      if (!_disposed && token == _speciesRequest) {
        _update(() => speciesLoading = false);
      }
    }
  }

  NarrativeCommandDescriptor? get command =>
      commands.where((command) => command.id == commandId).firstOrNull;

  bool _is2DPresentationCommand(String? id) =>
      id == NarrativeCommandIds.setMapEventInstanceBoolean ||
      id == NarrativeCommandIds.setNpcPose ||
      id == NarrativeCommandIds.setPropState ||
      id == NarrativeCommandIds.whiteOut ||
      id == NarrativeCommandIds.waitForActorRoutes ||
      id == NarrativeCommandIds.wait ||
      id == NarrativeCommandIds.worldTone ||
      id == NarrativeCommandIds.worldPresentation ||
      id == NarrativeCommandIds.playSoundEffect ||
      id == NarrativeCommandIds.stopSoundEffects ||
      id == NarrativeCommandIds.playMusicEffect;

  bool isActorCommand(String? id) =>
      id == NarrativeCommandIds.actorRoute ||
      id == NarrativeCommandIds.actorVisibility;

  void _readCurrent() {
    values.clear();
    error = null;
    commandId = null;
    final stored = current;
    unsupported = stored != null;
    if (stored is! SceneActionPayload) {
      loadReferenceMap();
      _loadGiftSpecies();
      return;
    }
    var data =
        stored.consequence?.toJson() ?? stored.interactiveCommand?.toJson();
    if (stored.interactiveCommand
        is SceneClaimPeriodicRewardInteractiveCommand) {
      data = Map<String, dynamic>.from(data!['definition'] as Map);
    }
    commandId =
        stored.consequence?.kind.name ?? stored.interactiveCommand?.kind.name;
    if (command == null || data == null) {
      commandId = null;
      loadReferenceMap();
      _loadGiftSpecies();
      return;
    }
    if (commandId == NarrativeCommandIds.openImagePuzzle &&
        stored.interactiveCommand is SceneOpenImagePuzzleInteractiveCommand) {
      unsupported = false;
      return;
    }
    if (isActorCommand(commandId)) {
      unsupported = false;
      loadReferenceMap();
      _loadGiftSpecies();
      return;
    }
    for (final parameter in command!.parameters) {
      final presentation = data['presentation'];
      final interruption = data['bgmInterruption'];
      final value = commandId == NarrativeCommandIds.warp && presentation is Map
          ? parameter.id == 'presentationMode'
                ? presentation['mode']
                : data[parameter.id] ?? presentation[parameter.id]
          : commandId == NarrativeCommandIds.playMusicEffect &&
                interruption is Map
          ? data[parameter.id] ?? interruption[parameter.id]
          : isIntegerSceneCommand(commandId)
          ? integerSceneStoredParameter(data, parameter.id)
          : data[parameter.id];
      if (value is String || value is num || value is bool) {
        values[parameter.id] = '$value';
      } else if (value is List &&
          (parameter.id == 'moveIds' ||
              parameter.id == 'propIds' ||
              parameter.id == 'factIds')) {
        values[parameter.id] = jsonEncode(value);
      }
    }
    if (data['mapId'] != null && data['entityId'] != null) {
      values['npcRef'] = '${data['mapId']}::${data['entityId']}';
    }
    final finish = stored.consequence;
    if (finish is SceneFinishGameConsequence) {
      values.addAll(sceneFinishGameAuthoringParameters(finish));
    }
    try {
      final rebuilt = buildPayload();
      unsupported = rebuilt != stored;
    } catch (_) {
      unsupported = true;
    }
    if (unsupported) commandId = null;
    giftMovesValid = !isGift || giftMoves == null;
    loadReferenceMap();
    _loadGiftSpecies();
    _loadItems();
  }

  SceneNodePayload buildPayload() => buildSceneActionDraftPayload(
    commandId: commandId!,
    parameters: values,
    original: current,
  );

  void choose(String commandId) => _update(() {
    this.commandId = commandId;
    error = null;
    values.clear();
    for (final parameter in command!.parameters) {
      if (parameter.kind == NarrativeCommandParameterKind.boolean &&
          parameter.required) {
        values[parameter.id] = 'true';
      } else if (parameter.kind == NarrativeCommandParameterKind.integer &&
          parameter.required) {
        values[parameter.id] = '1';
      }
    }
    if (isIntegerSceneCommand(commandId)) {
      values.addAll({
        'operandSource': 'literal',
        'operandValue': '0',
        'operation': commandId == NarrativeCommandIds.adjustMoney
            ? 'add'
            : 'assign',
        'minimum': '0',
        'maximum': '999',
        'digits': '3',
        'randomMinimum': '0',
        'randomMaximum': '4',
        'factIds': '[]',
        'zeroDivisorPolicy': 'reject',
        'boundaryPolicy': 'clamp',
        'cancellationPolicy': 'leaveUnchanged',
      });
    }
    if (commandId == NarrativeCommandIds.claimPeriodicReward) {
      final random = Random.secure();
      values['rewardId'] =
          'reward-${List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
    }
    _loadItems();
    giftMovesValid = true;
    if (commandId == NarrativeCommandIds.receivePokemonFromCatalog) {
      values['nicknamePolicy'] = 'offer';
      values['nicknameMaxGraphemes'] = '12';
      values['pokedexPresentationPolicy'] = 'never';
    }
    if (commandId == NarrativeCommandIds.sceneMusic) {
      values['operation'] = 'play';
      values['volume'] = '1';
      values['channel'] = 'music';
      values['scope'] = 'scene';
    }
    if (commandId == NarrativeCommandIds.stopSoundEffects) {
      values['scope'] = 'scene';
    }
    if (commandId == NarrativeCommandIds.playModelAnimation) {
      values['speed'] = '1';
    } else if (commandId == NarrativeCommandIds.setPropState) {
      values['durationMs'] = '350';
      values['state'] = 'open';
      values['propIds'] = '[]';
    } else if (commandId == NarrativeCommandIds.wait) {
      values['durationMs'] = '0';
    } else if (commandId == NarrativeCommandIds.worldTone) {
      for (final id in ['red', 'green', 'blue', 'gray', 'durationMs']) {
        values[id] = '0';
      }
    } else if (commandId == NarrativeCommandIds.playSoundEffect ||
        commandId == NarrativeCommandIds.playMusicEffect) {
      values['volume'] = '1';
      if (commandId == NarrativeCommandIds.playMusicEffect) {
        values['fadeOutMs'] = '0';
        values['fadeInMs'] = '0';
      }
    }
    loadReferenceMap();
    _loadGiftSpecies();
  });

  bool get valid {
    final command = this.command;
    if (command == null) return false;
    if (itemsLoading || itemsError != null) return false;
    if (command.id == NarrativeCommandIds.setMapEventInstanceBoolean &&
        (referenceLoading ||
            referenceError != null ||
            referenceMap == null ||
            !options(NarrativeCommandParameterKind.mapEntityReference)
                .containsKey(values['eventId']))) {
      return false;
    }
    if (command.id == NarrativeCommandIds.setPropState) {
      if (referenceLoading || referenceError != null || referenceMap == null) {
        return false;
      }
      try {
        final built = buildPayload() as SceneActionPayload;
        final command =
            built.interactiveCommand! as SceneSetPropStateInteractiveCommand;
        if (command.propIds.any((id) => !movingProps.containsKey(id))) {
          return false;
        }
      } catch (_) {
        return false;
      }
    }
    if (isGift && (speciesLoading || speciesError != null || !giftMovesValid)) {
      return false;
    }
    for (final parameter in command.parameters) {
      if (!warpFieldVisible(parameter)) continue;
      final value = values[parameter.id];
      if (parameter.kind == NarrativeCommandParameterKind.integerFacts) {
        try {
          final ids = (jsonDecode(value ?? '[]') as List).cast<String>();
          if (ids.isEmpty ||
              ids.toSet().length != ids.length ||
              ids.any((id) => !options(parameter.kind).containsKey(id))) {
            return false;
          }
        } catch (_) {
          return false;
        }
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
          !options(parameter.kind).containsKey(value)) {
        return false;
      }
    }
    if (command.id == NarrativeCommandIds.playModelAnimation) {
      final rawSpeed = values['speed']?.trim();
      final speed = double.tryParse(
        rawSpeed == null || rawSpeed.isEmpty ? '1' : rawSpeed,
      );
      if (speed == null || !speed.isFinite || speed <= 0 || speed > 16) {
        return false;
      }
    }
    if (command.id == NarrativeCommandIds.claimPeriodicReward ||
        isGift ||
        isIntegerSceneCommand(command.id) ||
        command.id == NarrativeCommandIds.warp ||
        command.id == NarrativeCommandIds.wait ||
        command.id == NarrativeCommandIds.worldTone ||
        command.id == NarrativeCommandIds.playSoundEffect ||
        command.id == NarrativeCommandIds.playMusicEffect ||
        command.id == NarrativeCommandIds.sceneMusic) {
      try {
        final payload = buildPayload();
        if (payload is SceneActionPayload) {
          final command = payload.interactiveCommand;
          if (command is SceneWarpInteractiveCommand &&
              command.presentation != null &&
              diagnoseInteractiveCommand(
                command: command,
                project: project,
              ).isNotEmpty) {
            return false;
          }
        }
      } catch (_) {
        return false;
      }
    }
    return true;
  }

  static const _warpPresentationFields = {
    'presentationMode',
    'illustrationElementId',
    'fadeOutMs',
    'transferDelayMs',
    'revealMs',
    'illustrationHoldMs',
    'illustrationFadeMs',
  };

  bool warpFieldVisible(NarrativeCommandParameterDescriptor parameter) {
    if (commandId == NarrativeCommandIds.claimPeriodicReward &&
        parameter.id == 'rewardId') {
      return false;
    }
    if (isIntegerSceneCommand(commandId)) {
      return integerSceneParameterVisible(parameter.id, values);
    }
    if (commandId == NarrativeCommandIds.sceneMusic) {
      return switch (parameter.id) {
        'mediaAssetId' || 'volume' => values['operation'] == 'play',
        'durationMs' => values['operation'] == 'fadeOut',
        _ => true,
      };
    }
    if (commandId != NarrativeCommandIds.warp) return true;
    final mode = values['presentationMode'];
    final active = mode != null && mode.isNotEmpty;
    if (parameter.id == 'transition') return !active;
    if (!_warpPresentationFields.contains(parameter.id)) return true;
    if (project.settings.dimension != ProjectDimension.twoD) return false;
    if (parameter.id == 'presentationMode') return true;
    if (!active) return false;
    if (const {
      'illustrationElementId',
      'illustrationHoldMs',
      'illustrationFadeMs',
    }.contains(parameter.id)) {
      return mode == 'illustrated' || mode == 'caveEntrance';
    }
    return true;
  }

  Map<String, String> _warpIllustrations() {
    final result = <String, String>{};
    for (final element in project.elements) {
      try {
        resolveSceneWarpPresentationVisual(
          SceneWarpPresentation(
            mode: SceneWarpPresentationMode.illustrated,
            illustrationElementId: element.id,
          ),
          project,
        );
        result[element.id] = element.name;
      } catch (_) {}
    }
    return result;
  }

  Map<String, String> _musicMediaOptions() {
    final counts = <String, int>{};
    for (final media in project.cinematicMediaAssets) {
      counts[media.id] = (counts[media.id] ?? 0) + 1;
    }
    return {
      for (final media in project.cinematicMediaAssets)
        if (counts[media.id] == 1 &&
            media.kind == CinematicMediaAssetKind.music)
          media.id: media.label,
    };
  }

  Map<String, String> _soundMediaOptions() {
    final counts = <String, int>{};
    for (final media in project.cinematicMediaAssets) {
      counts[media.id] = (counts[media.id] ?? 0) + 1;
    }
    return {
      for (final media in project.cinematicMediaAssets)
        if (counts[media.id] == 1 &&
            media.kind == CinematicMediaAssetKind.sound &&
            !media.loopByDefault)
          media.id: media.label,
    };
  }

  Map<String, String> _playerAvatarOptions() {
    final options = <String, String>{};
    for (final character in project.characters) {
      try {
        final avatar = resolveScenePlayerAvatarCharacter(project, character.id);
        options[avatar.id] = avatar.name;
      } on FormatException {
        continue;
      }
    }
    return options;
  }

  Map<String, String> options(NarrativeCommandParameterKind kind) =>
      integerSceneOptions(kind, project: project, commandId: commandId) ??
      switch (kind) {
        NarrativeCommandParameterKind.mapEntityReference => {
          for (final entity in referenceMap?.entities ?? const <MapEntity>[])
            if (referenceMap!.entities
                    .where((other) => other.id == entity.id)
                    .length ==
                1)
              entity.id: entity.name.trim().isNotEmpty
                  ? entity.name
                  : 'Élément (${entity.pos.x}, ${entity.pos.y})',
        },
        NarrativeCommandParameterKind.item => _items,
        NarrativeCommandParameterKind.character => _playerAvatarOptions(),
        NarrativeCommandParameterKind.species => {
          for (final species in species) species.id: species.name,
        },
        NarrativeCommandParameterKind.speciesForm => {
          for (final species in species)
            if (species.id == values['speciesId'])
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
          for (final fact in project.facts)
            if (fact.valueKind == NarrativeValueKind.boolean)
              fact.id: fact.label,
        },
        NarrativeCommandParameterKind.event => {
          for (final event
              in project.eventRegistry?.records ?? <NarrativeEventRecord>[])
            event.id: event.definitionOrNull?.name ?? event.draftOrNull!.name,
        },
        NarrativeCommandParameterKind.storyStep => {
          for (final story in project.storylines)
            for (final chapter in story.chapters)
              for (final step in chapter.steps)
                step.id: '${story.title} · ${step.title}',
        },
        NarrativeCommandParameterKind.map => {
          for (final map in project.maps)
            if (commandId != NarrativeCommandIds.waitForActorRoutes ||
                (map.id.isNotEmpty &&
                    map.id.trim() == map.id &&
                    project.maps.where((entry) => entry.id == map.id).length ==
                        1))
              map.id: map.name,
        },
        NarrativeCommandParameterKind.warp => _warpPoints,
        NarrativeCommandParameterKind.movingPropState => const {
          'closed': 'Fermé',
          'open': 'Ouvert',
        },
        NarrativeCommandParameterKind.characterDirection =>
          commandId == NarrativeCommandIds.warp
              ? const {
                  'north': 'Nord',
                  'south': 'Sud',
                  'east': 'Est',
                  'west': 'Ouest',
                }
              : const {},
        NarrativeCommandParameterKind.warpPresentationMode => const {
          '': 'Transition habituelle',
          'fade': 'Fondu noir',
          'illustrated': 'Illustration du lieu',
          'caveEntrance': 'Entrée de grotte',
          'caveExit': 'Sortie de grotte',
        },
        NarrativeCommandParameterKind.visualElementReference =>
          _warpIllustrations(),
        NarrativeCommandParameterKind.warpTransition => const {
          'mapDefault': 'Transition de la carte',
          'none': 'Sans transition',
        },
        NarrativeCommandParameterKind.modelInstance => _modelInstances,
        NarrativeCommandParameterKind.modelAnimation => _modelAnimations,
        NarrativeCommandParameterKind.soundMediaReference =>
          _soundMediaOptions(),
        NarrativeCommandParameterKind.musicMediaReference =>
          _musicMediaOptions(),
        NarrativeCommandParameterKind.sceneMusicOperation => const {
          'play': 'Jouer une musique en boucle',
          'restore': 'Restaurer l’état initial',
          'fadeOut': 'Fondre puis arrêter',
          'stop': 'Arrêter',
          'memorize': 'Mémoriser',
          'restoreMemorized': 'Restaurer la mémorisation',
        },
        NarrativeCommandParameterKind.sceneMusicChannel => {
          'music': 'Musique',
          if (project.settings.dimension != ProjectDimension.threeD)
            'ambience': 'Ambiance sonore',
          if (project.settings.dimension != ProjectDimension.threeD &&
              (values['operation'] == 'memorize' ||
                  values['operation'] == 'restoreMemorized'))
            'both': 'Les deux canaux',
        },
        NarrativeCommandParameterKind.sceneMusicScope => {
          'scene': 'Pendant la scène',
          if (project.settings.dimension != ProjectDimension.threeD)
            'map': 'Jusqu’au prochain transfert',
        },
        NarrativeCommandParameterKind.shop => {
          for (final shop in project.shops) shop.id: shop.label,
        },
        NarrativeCommandParameterKind.badge => {
          for (final badge in project.badges) badge.id: badge.label,
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
          for (final entry in ProjectPauseActionId.values)
            entry.name: entry.name,
        },
        _ => const {},
      };

  String presentationFieldHelp(String id) => switch (id) {
    'durationMs' =>
      commandId == NarrativeCommandIds.sceneMusic
          ? 'Millisecondes entières, de 0 à 60000.'
          : 'Millisecondes entières, de 0 à 2147483647.',
    'volume' => 'Entre 0 et 1.',
    'fadeOutMs' || 'fadeInMs' => 'Millisecondes entières, de 0 à 60000.',
    'gray' => 'Entre 0 et 255.',
    _ => 'Entre -255 et 255.',
  };

  String? presentationFieldError(String id) {
    final raw = values[id] ?? '';
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
                  (commandId == NarrativeCommandIds.sceneMusic
                      ? 60000
                      : 0x7fffffff)
          ? (commandId == NarrativeCommandIds.sceneMusic
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
        ? 'Saisir un nombre fini. ${presentationFieldHelp(id)}'
        : null;
  }

  void changeParameter(String id, String value) => _update(() {
    values[id] = value;
    error = null;
    if (commandId == NarrativeCommandIds.sceneMusic && id == 'operation') {
      if (values['channel'] == 'both' &&
          value != 'memorize' &&
          value != 'restoreMemorized') {
        values['channel'] = 'music';
      }
      for (final key in ['mediaAssetId', 'volume', 'durationMs']) {
        values.remove(key);
      }
      if (value == 'play') values['volume'] = '1';
      if (value == 'fadeOut') values['durationMs'] = '1000';
    }
    if (commandId == NarrativeCommandIds.warp && id == 'presentationMode') {
      if (value != 'illustrated' && value != 'caveEntrance') {
        for (final key in [
          'illustrationElementId',
          'illustrationHoldMs',
          'illustrationFadeMs',
        ]) {
          values.remove(key);
        }
      }
      if (value.isEmpty) {
        for (final key in ['fadeOutMs', 'transferDelayMs', 'revealMs']) {
          values.remove(key);
        }
      }
    }
    if (isGift && id == 'speciesId') {
      values['formId'] =
          species
              .where((species) => species.id == value)
              .firstOrNull
              ?.baseFormId ??
          '';
    }
    if (id == 'destinationMapId' && commandId == NarrativeCommandIds.warp) {
      values.remove('warpId');
      loadReferenceMap();
    } else if (id == 'mapId') {
      values.remove('eventId');
      values.remove('instanceId');
      values.remove('animationIndex');
      if (commandId == NarrativeCommandIds.setPropState) {
        values['propIds'] = '[]';
      }
      loadReferenceMap();
    } else if (id == 'instanceId') {
      values.remove('animationIndex');
    }
  });
}
