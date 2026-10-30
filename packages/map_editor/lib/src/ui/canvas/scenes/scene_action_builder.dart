import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../features/narrative/state/scene_consequence_catalog_providers.dart';
import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';
import 'scene_action_inspector.dart';
import 'scene_actor_action_builder.dart';
import 'scene_pokemon_gift_moves_editor.dart';
import 'scene_crafting_recipes_editor.dart';
import 'scene_image_puzzle_layout_editor.dart';

bool _isIntegerSceneCommand(String id) => const {
  NarrativeCommandIds.calculateIntegerFacts,
  NarrativeCommandIds.adjustMoney,
  NarrativeCommandIds.inputIntegerToFact,
  NarrativeCommandIds.tryPayMoney,
}.contains(id);

final class SceneActionPickerOption {
  const SceneActionPickerOption({
    required this.id,
    required this.label,
    this.parentId,
    this.isPrimarySpeciesForm = false,
    this.parameters = const {},
  });

  final String id;
  final String label;
  final String? parentId;
  final bool isPrimarySpeciesForm;
  final Map<String, String> parameters;
}

List<SceneActionPickerOption> buildScenePokemonFormPickerOptions(
  Iterable<SceneConsequenceCatalogOption> species,
) => [
  for (final entry in species)
    for (final formId in entry.formIds)
      SceneActionPickerOption(
        id: formId,
        label: scenePokemonFormLabel(formId),
        parentId: entry.id,
        isPrimarySpeciesForm: entry.catalogGiftFormIds.contains(formId),
      ),
];

List<SceneActionPickerOption> buildSceneImageMediaPickerOptions(ProjectMediaCatalog catalog) => [
  for (final media in catalog.entries)
    if (media.kind == ProjectMediaKind.image)
      SceneActionPickerOption(id: media.id, label: media.label),
];

List<SceneActionPickerOption> buildSceneSoundMediaPickerOptions(
  ProjectManifest project,
) {
  final counts = <String, int>{};
  for (final media in project.cinematicMediaAssets) {
    counts[media.id] = (counts[media.id] ?? 0) + 1;
  }
  return [
    for (final media in project.cinematicMediaAssets)
      if (counts[media.id] == 1 &&
          media.kind == CinematicMediaAssetKind.sound &&
          !media.loopByDefault)
        SceneActionPickerOption(id: media.id, label: media.label),
  ];
}

List<SceneActionPickerOption> buildSceneMusicMediaPickerOptions(
  ProjectManifest project,
) {
  final counts = <String, int>{};
  for (final media in project.cinematicMediaAssets) {
    counts[media.id] = (counts[media.id] ?? 0) + 1;
  }
  return [
    for (final media in project.cinematicMediaAssets)
      if (counts[media.id] == 1 && media.kind == CinematicMediaAssetKind.music)
        SceneActionPickerOption(id: media.id, label: media.label),
  ];
}

final class SceneActionBuildResult {
  const SceneActionBuildResult({
    required this.command,
    required this.payload,
    required this.parameters,
  });

  final NarrativeCommandDescriptor command;
  final SceneNodePayload payload;
  final Map<String, String> parameters;
}

/// Catalogue-driven, no-code Scene action form.
///
/// Reference parameters never fall back to a raw ID input: an empty catalogue
/// blocks publication and tells the creator which project catalogue is missing.
class SceneActionBuilder extends StatefulWidget {
  const SceneActionBuilder({
    super.key,
    required this.onSubmit,
    this.onSubmitResult,
    this.initialCommandId,
    this.commandCatalog,
    this.pickerOptions = const {},
    this.runtimeCommandIds,
    this.allowCommandSelection = true,
    this.initialParameters = const {},
    this.loadWarpMap,
    this.project,
    this.initialPayload,
    this.loadMoves,
  });

  final ValueChanged<SceneNodePayload> onSubmit;
  final ValueChanged<SceneActionBuildResult>? onSubmitResult;
  final String? initialCommandId;
  final NarrativeCommandCatalog? commandCatalog;
  final Map<NarrativeCommandParameterKind, List<SceneActionPickerOption>>
  pickerOptions;
  final Set<String>? runtimeCommandIds;
  final bool allowCommandSelection;
  final Map<String, String> initialParameters;
  final Future<MapData?> Function(String)? loadWarpMap;
  final ProjectManifest? project;
  final SceneActionPayload? initialPayload;
  final Future<Map<String, String>> Function()? loadMoves;

  @override
  State<SceneActionBuilder> createState() => _SceneActionBuilderState();
}

class _SceneActionBuilderState extends State<SceneActionBuilder> {
  late final NarrativeCommandCatalog _catalog;
  late String _commandId;
  final Map<String, String> _values = <String, String>{};
  final Map<String, TextEditingController> _textControllers = {};
  String? _submissionError;
  List<SceneActionPickerOption>? _loadedWarpOptions;
  List<SceneActionPickerOption>? _loadedPropOptions;
  List<SceneActionPickerOption>? _loadedLocalOwnerOptions;
  String? _warpReferenceError;
  bool _warpReferenceLoading = false;
  int _warpReferenceRequest = 0;
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

  @override
  void initState() {
    super.initState();
    _catalog = widget.commandCatalog ?? NarrativeCommandCatalog.canonical();
    _commandId = _initialCommandId();
    _seedParameterValues(_command);
  }

  NarrativeCommandDescriptor get _command => _catalog.byId(_commandId)!;

  bool _is2DPresentationCommand(String id) =>
      id == NarrativeCommandIds.setMapEventInstanceBoolean ||
      id == NarrativeCommandIds.inputTextToFact ||
      id == NarrativeCommandIds.setPropState ||
      id == NarrativeCommandIds.whiteOut ||
      id == NarrativeCommandIds.openRegionalMap ||
      id == NarrativeCommandIds.waitForActorRoutes ||
      id == NarrativeCommandIds.wait ||
      id == NarrativeCommandIds.worldTone ||
      id == NarrativeCommandIds.playSoundEffect;

  bool _isActorCommand(String id) =>
      id == NarrativeCommandIds.actorRoute ||
      id == NarrativeCommandIds.actorVisibility;

  List<NarrativeCommandDescriptor> get _availableCommands => [
    for (final command in _catalog.commands)
      if (command.capabilities.editor ==
              NarrativeCommandCapabilityStatus.supported &&
          _runtimeAllows(command) &&
          (!_is2DPresentationCommand(command.id) ||
              widget.project?.settings.dimension == ProjectDimension.twoD))
        if (!_isActorCommand(command.id) ||
            widget.project?.settings.dimension == ProjectDimension.twoD)
          command,
  ];

  bool _runtimeAllows(NarrativeCommandDescriptor command) {
    final runtimeCommandIds = widget.runtimeCommandIds;
    if (runtimeCommandIds != null) {
      return runtimeCommandIds.contains(command.id == NarrativeCommandIds.openNpcTrade
          ? NarrativeCommandIds.openPartyTrade : command.id);
    }
    return command.capabilities.runtime ==
        NarrativeCommandCapabilityStatus.supported;
  }

  String _initialCommandId() {
    final trade = widget.initialPayload?.interactiveCommand;
    if (widget.initialCommandId == null && trade is SceneOpenPartyTradeInteractiveCommand && trade.npcOffer != null) {
      return NarrativeCommandIds.openNpcTrade;
    }
    final requested =
        widget.initialCommandId ??
        widget.initialPayload?.interactiveCommand?.kind.name ??
        widget.initialPayload?.consequence?.kind.name;
    if (requested != null && _is2DPresentationCommand(requested) &&
        _catalog.byId(requested) != null) {
      return requested;
    }
    if (requested != null &&
        _availableCommands.any((command) => command.id == requested)) {
      return requested;
    }
    return _availableCommands.first.id;
  }

  void _seedParameterValues(NarrativeCommandDescriptor command) {
    _warpReferenceRequest++;
    _loadedWarpOptions = null;
    _warpReferenceError = null;
    _warpReferenceLoading = false;
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    _textControllers.clear();
    _values.clear();
    final previousSound = widget.initialPayload?.interactiveCommand;
    final previousFinish = widget.initialPayload?.consequence;
    final finishParameters = command.id == NarrativeCommandIds.finishGame &&
            previousFinish is SceneFinishGameConsequence
        ? sceneFinishGameAuthoringParameters(previousFinish)
        : const <String, String>{};
    for (final parameter in command.parameters) {
      var data =
          widget.initialPayload?.interactiveCommand?.toJson() ??
          widget.initialPayload?.consequence?.toJson() ??
          const <String, dynamic>{};
      if ((command.id == NarrativeCommandIds.openCrafting || command.id == NarrativeCommandIds.openImagePuzzle) && data['definition'] is Map) {
        data = {...Map<String, dynamic>.from(data['definition'] as Map), 'kind': command.id};
        if (command.id == NarrativeCommandIds.openImagePuzzle) {
          data['layout'] = jsonEncode({for (final field in ['allowedQuarterTurns', 'fixedPieceIds', 'initialPieces']) if (data.containsKey(field)) field: data[field]});
        }
      }
      if (command.id == NarrativeCommandIds.openNpcTrade && data['npcOffer'] is Map) {
        final offer = data['npcOffer'] as Map;
        final pokemon = offer['offeredPokemon'] as Map;
        data = {...data, 'kind': NarrativeCommandIds.openNpcTrade, 'offerName': offer['id'], 'requestedSpeciesId': offer['requestedSpeciesId'],
          'speciesId': pokemon['speciesId'], 'formId': pokemon['formId'],
          'nickname': pokemon['nickname'], 'level': pokemon['level'],
          'matchSelectedLevel': offer['matchSelectedLevel']};
      }
      final presentation = data['presentation'];
      final textFact = data['kind'] == NarrativeCommandIds.inputTextToFact && command.id == NarrativeCommandIds.inputTextToFact;
      final nestedText = textFact ? data[parameter.id] : null;
      final textFactValue = !textFact ? null : parameter.id == 'minGraphemes' || parameter.id == 'maxGraphemes'
          ? (data['constraints'] as Map? ?? const {})[parameter.id]
          : parameter.id == 'presetValues'
          ? (data['presetValues'] as List? ?? const []).join('\n')
          : nestedText is Map ? nestedText['fallbackText'] : nestedText;
      final storedValue =
          command.id == NarrativeCommandIds.playSoundEffect &&
              parameter.id == 'waitForCompletion' &&
              previousSound is ScenePlaySoundEffectInteractiveCommand
          ? previousSound.waitForCompletion
          :
          finishParameters.containsKey(parameter.id)
          ? finishParameters[parameter.id]
          :
          data['kind'] == command.id &&
              (_is2DPresentationCommand(command.id) ||
                  command.id == NarrativeCommandIds.sceneMusic ||
                  command.id == NarrativeCommandIds.warp ||
                  command.id == NarrativeCommandIds.setPlayerAvatar ||
                  command.id == NarrativeCommandIds.markPokemonSeen ||
                  command.id == NarrativeCommandIds.setNpcPose ||
                  command.id == NarrativeCommandIds.adjustIntegerFact ||
                  _isIntegerSceneCommand(command.id) ||
                  command.id == NarrativeCommandIds.receivePokemonFromCatalog ||
                  command.id == NarrativeCommandIds.openCrafting ||
                  command.id == NarrativeCommandIds.openImagePuzzle ||
                  command.id == NarrativeCommandIds.openNpcTrade ||
                  command.id == NarrativeCommandIds.givePokemonFromCatalog)
          ? textFact ? textFactValue : command.id == NarrativeCommandIds.warp && presentation is Map
              ? parameter.id == 'presentationMode' ? presentation['mode']
                  : data[parameter.id] ?? presentation[parameter.id]
                : _isIntegerSceneCommand(command.id)
                ? _integerStoredParameter(data, parameter.id)
                : command.id == NarrativeCommandIds.setNpcPose && parameter.id == 'npcRef'
                ? '${data['mapId']}::${data['entityId']}'
                : command.id == NarrativeCommandIds.setNpcPose && parameter.id == 'facing' ? data['facing'] ?? '' : data[parameter.id]
          : null;
      final initial =
          widget.initialParameters[parameter.id] ??
          (storedValue is String || storedValue is num || storedValue is bool
              ? '$storedValue'
              : storedValue is List
              ? jsonEncode(storedValue)
              : null);
      switch (parameter.kind) {
        case NarrativeCommandParameterKind.boolean:
          _values[parameter.id] = (initial == 'false' || storedValue == false ||
              initial == null && command.id == NarrativeCommandIds.openImagePuzzle && parameter.id == 'allowSwap' ||
              initial == null && command.id == NarrativeCommandIds.finishGame &&
                  parameter.id == 'recordParty')
              ? 'false' : 'true';
        case NarrativeCommandParameterKind.integer:
          final value =
              initial ??
              (_isIntegerSceneCommand(command.id)
                  ? parameter.id == 'initialValue'
                        ? ''
                        : parameter.id == 'digits'
                        ? '3'
                        : parameter.id == 'maximum'
                        ? '999'
                        : parameter.id == 'randomMaximum'
                        ? '4'
                        : '0'
                  : command.id == NarrativeCommandIds.openImagePuzzle && (parameter.id == 'rows' || parameter.id == 'columns') ? '4' :
              command.id == NarrativeCommandIds.inputTextToFact && parameter.id == 'maxGraphemes' ? '7' :
              command.id == NarrativeCommandIds.setPropState ? '350' :
              command.id == NarrativeCommandIds.adjustIntegerFact && parameter.id == 'minimum' ? '0' :
              command.id == NarrativeCommandIds.adjustIntegerFact && parameter.id == 'maximum' ? '100' :
              (command.id == NarrativeCommandIds.receivePokemonFromCatalog && parameter.id == 'nicknameMaxGraphemes' ? '12' :
              command.id == NarrativeCommandIds.warp && !parameter.required ? '' :
              ((command.id == NarrativeCommandIds.worldTone ||
                       command.id == NarrativeCommandIds.wait) &&
                      parameter.id == 'durationMs'
                  ? '0'
                  : '1')));
          _values[parameter.id] = value;
          _textControllers[parameter.id] = TextEditingController(text: value);
        case NarrativeCommandParameterKind.number:
          final value =
              initial ??
              (command.id == NarrativeCommandIds.playSoundEffect ? '1' : '0');
          _values[parameter.id] = value;
          _textControllers[parameter.id] = TextEditingController(text: value);
        case NarrativeCommandParameterKind.text:
          final value = initial ?? '';
          _values[parameter.id] = value;
          _textControllers[parameter.id] = TextEditingController(text: value);
        case NarrativeCommandParameterKind.imagePuzzleLayout:
          _values[parameter.id] = initial ?? jsonEncode({'allowedQuarterTurns': [0, 1, 2, 3], 'fixedPieceIds': <int>[]});
        case NarrativeCommandParameterKind.deferredCraftingRecipes:
        case NarrativeCommandParameterKind.integerFacts:
        case NarrativeCommandParameterKind.movingProps:
          _values[parameter.id] = initial ?? '[]';
        default:
          final options = _optionsFor(parameter.kind);
          final strictWarpOption = command.id == NarrativeCommandIds.warp &&
              (parameter.id == 'arrivalFacing' || parameter.id == 'transition') ||
              command.id == NarrativeCommandIds.setNpcPose && parameter.id == 'facing';
          if (initial != null &&
              (initial.trim().isNotEmpty || strictWarpOption && initial.isNotEmpty)) {
            _values[parameter.id] = strictWarpOption ? initial : initial.trim();
          } else if (options.isNotEmpty && parameter.kind != NarrativeCommandParameterKind.visualElementReference) {
            _values[parameter.id] = options.first.id;
          }
      }
    }
    for (final parameter in command.parameters) {
      final value = _values[parameter.id];
      if (_isReferenceParameter(parameter) && value != null) {
        _applyOptionParameters(parameter.kind, value);
      }
    }
    if (_isGift && (_values['moveIds']?.isEmpty ?? false)) {
      _values.remove('moveIds');
    }
    if (command.id == NarrativeCommandIds.sceneMusic) {
      if (widget.initialPayload == null && widget.initialParameters.isEmpty) {
        _values['volume'] = '1';
      }
      _syncMusicOperation();
    }
    if (command.id == NarrativeCommandIds.setNpcPose) {
      final pose = widget.initialPayload is SceneActionPayload ? (widget.initialPayload as SceneActionPayload).consequence : null;
      _npcPosePosition = pose is SceneSetNpcPoseConsequence ? pose.x != null :
          widget.initialParameters['x']?.isNotEmpty == true || widget.initialParameters['y']?.isNotEmpty == true;
      if (!_npcPosePosition) {
        _values.remove('x');
        _values.remove('y');
      }
    }
    _giftMovesValid = !_isGift || _giftMoves == null;
    _loadWarpReferences(selectFirst: true);
  }

  @override
  void didUpdateWidget(SceneActionBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isGift &&
        _giftMoves != null &&
        oldWidget.loadMoves != widget.loadMoves) {
      _giftMovesValid = false;
    }
    if ((_isGift || _commandId == NarrativeCommandIds.setPlayerAvatar ||
        _commandId == NarrativeCommandIds.adjustIntegerFact ||
        _commandId == NarrativeCommandIds.markPokemonSeen || _commandId == NarrativeCommandIds.setNpcPose ||
        _commandId == NarrativeCommandIds.setMapEventInstanceBoolean) &&
        oldWidget.initialPayload != widget.initialPayload) {
      _seedParameterValues(_command);
    }
    if (oldWidget.loadWarpMap != widget.loadWarpMap ||
        oldWidget.pickerOptions != widget.pickerOptions) {
      _loadWarpReferences();
    }
  }

  void _loadWarpReferences({bool selectFirst = false}) {
    final request = ++_warpReferenceRequest;
    _loadedWarpOptions = null;
    _loadedPropOptions = null;
    _loadedLocalOwnerOptions = null;
    _warpReferenceError = null;
    _warpReferenceLoading = false;
    final load = widget.loadWarpMap;
    final isProp = _command.id == NarrativeCommandIds.setPropState;
    final isLocal = _command.id == NarrativeCommandIds.setMapEventInstanceBoolean;
    final mapId = _values[isProp || isLocal ? 'mapId' : 'destinationMapId'];
    if ((_command.id != NarrativeCommandIds.warp && !isProp && !isLocal) ||
        load == null ||
        mapId == null ||
        !_optionsFor(
          NarrativeCommandParameterKind.map,
        ).any((option) => option.id == mapId)) {
      return;
    }
    _warpReferenceLoading = true;
    Future<MapData?>.sync(() => load(mapId)).then(
      (map) {
        if (!mounted || request != _warpReferenceRequest) return;
        setState(() {
          _warpReferenceLoading = false;
          if (isLocal) {
            if (map == null || map.id != mapId || map.spatialScene != null || map.version == ProjectVersion.v9) {
              _warpReferenceError = 'La mémoire locale nécessite une carte 2D disponible.';
              return;
            }
            _loadedLocalOwnerOptions = [for (final entity in map.entities)
              if (map.entities.where((candidate) => candidate.id == entity.id).length == 1)
                SceneActionPickerOption(id: entity.id, parentId: map.id,
                  label: entity.name.isEmpty ? 'Élément (${entity.pos.x}, ${entity.pos.y})' : entity.name),
            ];
            return;
          }
          if (isProp) {
            if (map == null || map.id != mapId || map.spatialScene != null ||
                map.movingProps.map((prop) => prop.id).toSet().length != map.movingProps.length) {
              _warpReferenceError = 'La carte des décors mobiles est absente ou incohérente.';
              return;
            }
            _loadedPropOptions = [for (final prop in map.movingProps)
              SceneActionPickerOption(id: prop.id, parentId: map.id,
                label: '${widget.project?.elements.where((element) => element.id == map.placedElements.where((placement) => placement.id == prop.placedElementId).firstOrNull?.elementId).firstOrNull?.name ?? 'Décor'} · (${prop.closedPositionPx.x}, ${prop.closedPositionPx.y})',
                ),
            ];
            return;
          }
          if (map == null ||
              map.id != mapId ||
              map.warps.map((warp) => warp.id).toSet().length !=
                  map.warps.length) {
            _warpReferenceError =
                'La carte d’arrivée est absente ou incohérente.';
            return;
          }
          _loadedWarpOptions = List<SceneActionPickerOption>.unmodifiable([
            for (final warp in map.warps)
              SceneActionPickerOption(
                id: warp.id,
                label: '${map.name} → ${warp.targetMapId}',
                parentId: map.id,
              ),
          ]);
          if (selectFirst &&
              (_values['warpId']?.isEmpty ?? true) &&
              _loadedWarpOptions!.isNotEmpty) {
            _values['warpId'] = _loadedWarpOptions!.first.id;
          }
        });
      },
      onError: (Object error) {
        if (!mounted || request != _warpReferenceRequest) return;
        setState(() {
          _warpReferenceLoading = false;
          _warpReferenceError =
              'Impossible de lire les points d’arrivée de cette carte.';
        });
      },
    );
  }

  @override
  void dispose() {
    _warpReferenceRequest++;
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _npcPosePosition = true;

  List<NarrativeCommandParameterDescriptor> get _missingParameters =>
      _isActorCommand(_command.id)
      ? const []
      : [
          for (final parameter in _command.parameters)
            if (_isParameterVisible(parameter) &&
                (_isParameterRequired(parameter) ||
                    _command.id == NarrativeCommandIds.warp &&
                        (parameter.id == 'arrivalFacing' ||
                            parameter.id == 'transition') &&
                        (_values[parameter.id]?.isNotEmpty ?? false)) &&
                !_hasValidValue(parameter))
              parameter,
        ];

  bool _isParameterRequired(NarrativeCommandParameterDescriptor parameter) {
    if (_command.id == NarrativeCommandIds.setNpcPose) {
      if (parameter.id == 'x' || parameter.id == 'y') return _npcPosePosition;
      if (parameter.id == 'facing') return !_npcPosePosition;
    }
    if (_command.id == NarrativeCommandIds.sceneMusic) return _isParameterVisible(parameter);
    if (_command.id == NarrativeCommandIds.warp && parameter.id == 'illustrationElementId') {
      return _values['presentationMode'] == 'illustrated' || _values['presentationMode'] == 'caveEntrance';
    }
    if (_command.id == NarrativeCommandIds.railJourney) {
      final operation = _values['operation'];
      if (parameter.id == 'direction') {
        return operation == 'begin';
      }
      if (parameter.id == 'advanceEvent') {
        return operation == 'advance';
      }
      if (parameter.id == 'doorSide') {
        return operation == 'begin' ||
            operation == 'advance' &&
                _values['advanceEvent'] == 'destinationDoorUsed';
      }
    }
    if (_command.id == NarrativeCommandIds.playCharacterAnimation &&
        parameter.id == 'direction') {
      return _values['animationMode'] == 'directional';
    }
    if (_command.id == NarrativeCommandIds.finishGame &&
        _values['includeCredits'] == 'true' &&
        const {
          'creditsTitle',
          'creditsAuthor',
          'creditsEndingLabel',
        }.contains(parameter.id)) {
      return true;
    }
    return parameter.required;
  }

  bool _isParameterVisible(NarrativeCommandParameterDescriptor parameter) {
    if (_isIntegerSceneCommand(_command.id)) {
      return switch (parameter.id) {
        'operandValue' => _values['operandSource'] == 'literal',
        'operandFactId' => _values['operandSource'] == 'integerFact',
        'operandItemId' => _values['operandSource'] == 'itemCount',
        'randomMinimum' ||
        'randomMaximum' => _values['operandSource'] == 'random',
        'zeroDivisorPolicy' =>
          _values['operation'] == 'floorDivide' ||
              _values['operation'] == 'modulo',
        _ => true,
      };
    }
    if (_command.id == NarrativeCommandIds.setNpcPose && (parameter.id == 'x' || parameter.id == 'y')) return _npcPosePosition;
    if (_command.id == NarrativeCommandIds.sceneMusic) {
      return switch (parameter.id) {
        'mediaAssetId' || 'volume' => _values['operation'] == 'play',
        'durationMs' => _values['operation'] == 'fadeOut',
        _ => true,
      };
    }
    if (_command.id == NarrativeCommandIds.warp) {
      final mode = _values['presentationMode'];
      final active = mode != null && mode.isNotEmpty;
      if (parameter.id == 'transition') return !active;
      if (const {'presentationMode', 'illustrationElementId', 'fadeOutMs', 'transferDelayMs',
          'revealMs', 'illustrationHoldMs', 'illustrationFadeMs',
      }.contains(parameter.id)) {
        if (widget.project?.settings.dimension != ProjectDimension.twoD) return false;
        if (parameter.id == 'presentationMode') return true;
        if (!active) return false;
        if (const {'illustrationElementId', 'illustrationHoldMs', 'illustrationFadeMs',
        }.contains(parameter.id)) {
          return mode == 'illustrated' || mode == 'caveEntrance';
        }
        return true;
      }
    }
    if (_command.id == NarrativeCommandIds.railJourney) {
      final operation = _values['operation'];
      if (parameter.id == 'direction') {
        return operation == 'begin';
      }
      if (parameter.id == 'advanceEvent') {
        return operation == 'advance';
      }
      if (parameter.id == 'doorSide') {
        return operation == 'begin' ||
            operation == 'advance' &&
                _values['advanceEvent'] == 'destinationDoorUsed';
      }
    }
    if (_command.id == NarrativeCommandIds.playCharacterAnimation) {
      if (parameter.id == 'direction') {
        return _values['animationMode'] == 'directional';
      }
      if (parameter.id == 'repeatCount') {
        return _values['playbackKind'] == 'repeatCount';
      }
      if (parameter.id == 'durationMs') {
        return _values['playbackKind'] == 'forDuration';
      }
    }
    if (_command.id != NarrativeCommandIds.finishGame) return true;
    if (!parameter.id.startsWith('credits') ||
        parameter.id == 'includeCredits') {
      return true;
    }
    return _values['includeCredits'] == 'true';
  }

  bool _hasValidValue(NarrativeCommandParameterDescriptor parameter) {
    if (parameter.kind == NarrativeCommandParameterKind.imagePuzzleLayout) {
      try { buildScenePayloadForNarrativeCommand(commandId: _command.id, parameters: _values); return true; } catch (_) { return false; }
    }
    if (parameter.kind == NarrativeCommandParameterKind.deferredCraftingRecipes) {
      try {
        final rows = (jsonDecode(_values[parameter.id] ?? '[]') as List).map((value) => DeferredCraftingRecipe.fromJson(Map<String, dynamic>.from(value as Map))).toList();
        final ids = _optionsFor(NarrativeCommandParameterKind.item).map((item) => item.id).toSet();
        return rows.isNotEmpty && rows.map((recipe) => recipe.recipeId).toSet().length == rows.length && rows.every((recipe) => ids.contains(recipe.inputItemId) && ids.contains(recipe.outputItemId));
      } catch (_) { return false; }
    }
    if (parameter.kind == NarrativeCommandParameterKind.integerFacts) {
      try {
        final ids = (jsonDecode(_values[parameter.id] ?? '[]') as List)
            .cast<String>();
        return ids.isNotEmpty &&
            ids.toSet().length == ids.length &&
            ids.every(
              (id) =>
                  _optionsFor(parameter.kind).any((option) => option.id == id),
            );
      } catch (_) {
        return false;
      }
    }
    final rawValue = _values[parameter.id];
    final value = rawValue?.trim();
    if (parameter.kind == NarrativeCommandParameterKind.movingProps) {
      try {
        final payload = buildScenePayloadForNarrativeCommand(commandId: _command.id, parameters: _values,
                ) as SceneActionPayload;
        final command = payload.interactiveCommand! as SceneSetPropStateInteractiveCommand;
        return command.propIds.every((id) => _optionsFor(parameter.kind).any((option) => option.id == id),
        );
      } catch (_) { return false; }
    }
    if (_command.id == NarrativeCommandIds.warp &&
        (parameter.id == 'arrivalFacing' || parameter.id == 'transition') &&
        rawValue != value) {
      return false;
    }
    if (value == null || value.isEmpty) return false;
    if (parameter.kind == NarrativeCommandParameterKind.integer) {
      if (_command.id == NarrativeCommandIds.adjustIntegerFact ||
          _isIntegerSceneCommand(_command.id)) {
        final parsed = int.tryParse(value);
        if (parsed == null || parsed.toString() != value) return false;
        try {
          NarrativeValue.integer(parsed);
          return true;
        } on ArgumentError {
          return false;
        }
      }
      if ((_command.id == NarrativeCommandIds.worldTone ||
           _command.id == NarrativeCommandIds.wait) &&
          parameter.id == 'durationMs') {
        return _hasValidPresentationParameter(parameter.id, value);
      }
      final parsed = int.tryParse(value);
      if (_command.id == NarrativeCommandIds.sceneMusic) return parsed != null && parsed >= 0 && parsed <= 60000;
      if (_command.id == NarrativeCommandIds.receivePokemonFromCatalog && (parameter.id == 'level' || parameter.id == 'nicknameMaxGraphemes')) {
        return parsed != null && parsed >= 1 && parsed <= 100;
      }
      return parsed != null && parsed > 0;
    }
    if (parameter.kind == NarrativeCommandParameterKind.number) {
      final parsed = double.tryParse(value);
      return parsed != null &&
          parsed.isFinite &&
          _hasValidPresentationParameter(parameter.id, value);
    }
    if (_isReferenceParameter(parameter)) {
      final options = _optionsFor(parameter.kind);
      return options.any((option) => option.id == value);
    }
    return true;
  }

  bool _isReferenceParameter(NarrativeCommandParameterDescriptor parameter) =>
      parameter.kind != NarrativeCommandParameterKind.boolean &&
      parameter.kind != NarrativeCommandParameterKind.integer &&
      parameter.kind != NarrativeCommandParameterKind.number &&
      parameter.kind != NarrativeCommandParameterKind.text;

  bool _hasValidPresentationParameter(String parameterId, String value) {
    final defaults = switch (_command.id) {
      NarrativeCommandIds.wait => const {'durationMs': '0'},
      NarrativeCommandIds.worldTone => const {
        'red': '0',
        'green': '0',
        'blue': '0',
        'gray': '0',
        'durationMs': '0',
      },
      NarrativeCommandIds.sceneMusic => const {
        'operation': 'play',
        'mediaAssetId': 'validation.music',
        'volume': '1',
      },
      NarrativeCommandIds.playSoundEffect => const {
        'mediaAssetId': 'validation.sound',
        'volume': '1',
      },
      _ => null,
    };
    if (defaults == null) return true;
    try {
      buildScenePayloadForNarrativeCommand(
        commandId: _command.id,
        parameters: {...defaults, parameterId: value},
      );
      return true;
    } on ArgumentError {
      return false;
    } on FormatException {
      return false;
    }
  }

  bool get _validWarpPresentation {
    if (_command.id != NarrativeCommandIds.warp) return true;
    try {
      final payload = buildScenePayloadForNarrativeCommand(commandId: _command.id, parameters: _values,
              ) as SceneActionPayload;
      final command = payload.interactiveCommand! as SceneWarpInteractiveCommand;
      if (command.presentation == null) return true;
      return widget.project != null && diagnoseInteractiveCommand(command: command, project: widget.project!,
          ).isEmpty;
    } catch (_) { return false; }
  }

  bool get _canSubmit =>
      _command.capabilities.editor ==
          NarrativeCommandCapabilityStatus.supported &&
      _runtimeAllows(_command) &&
      (!_is2DPresentationCommand(_command.id) ||
          widget.project?.settings.dimension == ProjectDimension.twoD) &&
      ((_command.id != NarrativeCommandIds.warp && _command.id != NarrativeCommandIds.setPropState &&
          _command.id != NarrativeCommandIds.setMapEventInstanceBoolean) ||
          !_warpReferenceLoading && _warpReferenceError == null) &&
      _missingParameters.isEmpty &&
      _validWarpPresentation &&
      _validTextFactInput &&
      _validIntegerAdjustment &&
      _validSceneMusic &&
      (!_isGift || _giftMovesValid);

  bool get _validSceneMusic {
    if (_command.id != NarrativeCommandIds.sceneMusic) return true;
    try {
      buildScenePayloadForNarrativeCommand(
        commandId: _command.id,
        parameters: _values,
      );
      return true;
    } on ArgumentError {
      return false;
    } on FormatException {
      return false;
    }
  }

  void _syncMusicOperation() {
    final operation = _values['operation'];
    for (final key in ['mediaAssetId', 'volume', 'durationMs']) {
      if (operation == 'play' && key != 'durationMs' ||
          operation == 'fadeOut' && key == 'durationMs') {
        continue;
      }
      _values.remove(key);
      _textControllers[key]?.text = '';
    }
    if (operation == 'play') {
      _values.putIfAbsent('volume', () => '1');
      _textControllers['volume']?.text = _values['volume']!;
    }
    if (operation == 'fadeOut') {
      _values.putIfAbsent('durationMs', () => '1000');
      _textControllers['durationMs']?.text = _values['durationMs']!;
    }
  }

  bool get _validTextFactInput {
    if (_command.id != NarrativeCommandIds.inputTextToFact) return true;
    try {
      buildScenePayloadForNarrativeCommand(commandId: _command.id, parameters: _values,
      );
      return true;
    } on ArgumentError {
      return false;
    } on FormatException {
      return false;
    }
  }

  bool get _validIntegerAdjustment {
    if (_command.id != NarrativeCommandIds.adjustIntegerFact &&
        !_isIntegerSceneCommand(_command.id)) {
      return true;
    }
    try {
      buildScenePayloadForNarrativeCommand(commandId: _command.id, parameters: _values,
      );
      return true;
    } on ArgumentError {
      return false;
    } on FormatException {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapPanel(
      header: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          _command.id == NarrativeCommandIds.receivePokemonFromCatalog && widget.initialPayload != null ? 'Modifier le cadeau Pokémon' : 'Ajouter une action',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      footer: _isActorCommand(_command.id)
          ? null
          : Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.centerRight,
                child: PokeMapButton(
                  key: const ValueKey('scene-action-submit'),
                  onPressed: _canSubmit ? _submit : null,
                  variant: PokeMapButtonVariant.primary,
                  child: Text(_command.id == NarrativeCommandIds.receivePokemonFromCatalog && widget.initialPayload != null ? 'Appliquer les modifications' : 'Ajouter à la Scene',
                  ),
                ),
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.allowCommandSelection) ...[
            PokeMapDropdownField<String>(
              label: 'Type de commande',
              value: _commandId,
              items: [
                for (final command in _availableCommands)
                  PokeMapDropdownItem(value: command.id, label: command.label),
              ],
              onChanged: (value) {
                setState(() {
                  _commandId = value;
                  _submissionError = null;
                  _seedParameterValues(_command);
                });
              },
            ),
            const SizedBox(height: 12),
          ],
          if (_is2DPresentationCommand(_command.id) &&
              widget.project?.settings.dimension != ProjectDimension.twoD)
            const PokeMapDiagnosticCallout(
              severity: PokeMapDiagnosticSeverity.error,
              title: 'Commande 2D indisponible',
              message: 'Cette commande exige un projet 2D. Le brouillon reste conservé.',
            ),
          SceneActionInspector(
            command: _command,
            missingParameterLabels: _missingParameters
                .map((parameter) => parameter.label)
                .toList(),
          ),
          if (_commandId == NarrativeCommandIds.whiteOut)
            const PokeMapDiagnosticCallout(
              severity: PokeMapDiagnosticSeverity.info,
              title: 'Défaite scénarisée',
              message: 'À la fin réussie de la Scene, l’équipe est soignée, la pénalité de défaite est appliquée et le joueur revient au point de reprise. Une seule récupération par Scene.',
            ),
          if (_isActorCommand(_command.id))
            if (widget.project case final project?)
              SceneActorActionBuilder(
                key: ValueKey(_commandId),
                project: project,
                commandId: _commandId,
                current: widget.initialPayload,
                loadMap: widget.loadWarpMap,
                onApply: (payload) {
                  widget.onSubmitResult?.call(
                    SceneActionBuildResult(
                      command: _command,
                      payload: payload,
                      parameters: payload is SceneActionPayload
                          ? payload.parameters
                          : const {},
                    ),
                  );
                  widget.onSubmit(payload);
                },
              )
            else
              const PokeMapDiagnosticCallout(
                severity: PokeMapDiagnosticSeverity.error,
                title: 'Projet indisponible',
                message: 'Ouvrir un projet 2D pour choisir un acteur.',
              ),
          if (_command.id == NarrativeCommandIds.setNpcPose)
            PokeMapDropdownField<String>(label: 'Modification du PNJ',
              value: _npcPosePosition ? 'position' : 'facing',
              items: const [
                PokeMapDropdownItem(value: 'position', label: 'Position et direction',
                ),
                PokeMapDropdownItem(value: 'facing', label: 'Direction uniquement',
                ),
              ],
              onChanged: (value) => setState(() {
                _npcPosePosition = value == 'position';
                if (_npcPosePosition) {
                  _values['x'] = '0';
                  _values['y'] = '0';
                } else {
                  _values.remove('x');
                  _values.remove('y');
                  if (_values['facing']?.isNotEmpty != true) _values['facing'] = 'south';
                }
              }),
            ),
          if (!_isActorCommand(_command.id))
            for (final parameter in _command.parameters)
              if (_isParameterVisible(parameter)) ...[
                const SizedBox(height: 12),
                _buildParameter(parameter),
              ],
          if (_submissionError != null) ...[
            const SizedBox(height: 12),
            PokeMapDiagnosticCallout(
              severity: PokeMapDiagnosticSeverity.error,
              title: 'Action refusée',
              message: _submissionError!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParameter(NarrativeCommandParameterDescriptor parameter) {
    if (parameter.kind == NarrativeCommandParameterKind.imagePuzzleLayout) {
      return SceneImagePuzzleLayoutEditor(rows: int.tryParse(_values['rows'] ?? '') ?? 0, columns: int.tryParse(_values['columns'] ?? '') ?? 0, trayCapacity: int.tryParse(_values['trayCapacity'] ?? '') ?? 0, value: Map<String, dynamic>.from(jsonDecode(_values[parameter.id]!) as Map), onChanged: (next) => _setValue(parameter.id, jsonEncode(next)));
    }
    if (parameter.kind == NarrativeCommandParameterKind.deferredCraftingRecipes) {
      final rows = (jsonDecode(_values[parameter.id] ?? '[]') as List).map((value) => Map<String, dynamic>.from(value as Map)).toList();
      return SceneCraftingRecipesEditor(value: rows, items: {for (final item in _optionsFor(NarrativeCommandParameterKind.item)) item.id: item.label}, onChanged: (value) => _setValue(parameter.id, jsonEncode(value)));
    }
    if (parameter.kind == NarrativeCommandParameterKind.integerFacts) {
      final selected = <String>{};
      try {
        selected.addAll(
          (jsonDecode(_values[parameter.id] ?? '[]') as List).cast<String>(),
        );
      } catch (_) {}
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(parameter.label),
          for (final option in _optionsFor(parameter.kind))
            PokeMapToggleTile(
              key: ValueKey('scene-integer-fact-${option.id}'),
              label: option.label,
              value: selected.contains(option.id),
              onChanged: (value) => setState(() {
                final next = {...selected};
                value ? next.add(option.id) : next.remove(option.id);
                _values[parameter.id] = jsonEncode(next.toList());
              }),
            ),
        ],
      );
    }
    if (parameter.kind == NarrativeCommandParameterKind.movingProps) {
      final selected = <String>{};
      try { selected.addAll((jsonDecode(_values['propIds'] ?? '[]') as List).cast<String>(),
        ); } catch (_) {}
      final options = _optionsFor(parameter.kind);
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(parameter.label),
        if (_warpReferenceLoading) const PokeMapDiagnosticCallout(
          severity: PokeMapDiagnosticSeverity.info, title: 'Chargement des décors mobiles', message: 'Lecture de la carte sélectionnée.',
            ),
        if (_warpReferenceError != null) PokeMapDiagnosticCallout(
          severity: PokeMapDiagnosticSeverity.error, title: 'Décors indisponibles', message: _warpReferenceError!,
            ),
        if (!_warpReferenceLoading && _warpReferenceError == null && options.isEmpty)
          const PokeMapDiagnosticCallout(severity: PokeMapDiagnosticSeverity.info,
            title: 'Aucun décor mobile', message: 'Configurez les décors mobiles dans les propriétés des décors de cette carte.',
            ),
        for (final missing in selected.difference(options.map((option) => option.id).toSet(),
          ))
          PokeMapDiagnosticCallout(severity: PokeMapDiagnosticSeverity.error,
            title: 'Décor supprimé', message: 'Une référence sélectionnée n’existe plus.',
            actionLabel: 'Retirer la référence absente',
            onAction: () => setState(() => _values['propIds'] = jsonEncode(selected.difference({missing}).toList(),
                ),
              ),
            ),
        for (final option in options)
          PokeMapToggleTile(key: ValueKey('scene-prop-${option.id}'), label: option.label,
            value: selected.contains(option.id), onChanged: (value) => setState(() {
              final next = {...selected}; value ? next.add(option.id) : next.remove(option.id);
              _values['propIds'] = jsonEncode(next.toList());
            }),
            ),
        ],
      );
    }
    if (_isGift && parameter.id == 'moveIds') {
      return ScenePokemonGiftMovesEditor(
        key: ValueKey('gift-moves-$_commandId'),
        value: _giftMoves,
        loadMoves: widget.loadMoves,
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
    switch (parameter.kind) {
      case NarrativeCommandParameterKind.boolean:
        return PokeMapDropdownField<String>(
          label: parameter.label,
          value: _values[parameter.id] ?? 'true',
          items:
              _command.id == NarrativeCommandIds.setPauseMenuEntryVisibility &&
                  parameter.id == 'visible'
              ? const [
                  PokeMapDropdownItem(value: 'true', label: 'Afficher'),
                  PokeMapDropdownItem(value: 'false', label: 'Masquer'),
                ]
              : const [
                  PokeMapDropdownItem(value: 'true', label: 'Vrai'),
                  PokeMapDropdownItem(value: 'false', label: 'Faux'),
                ],
          onChanged: (value) => _setReferenceValue(parameter, value),
        );
      case NarrativeCommandParameterKind.integer:
      case NarrativeCommandParameterKind.number:
      case NarrativeCommandParameterKind.text:
        return PokeMapTextField(
          label: parameter.label,
          fieldKey: ValueKey('scene-action-parameter-${parameter.id}'),
          controller: _textControllers[parameter.id],
          maxLines: _command.id == NarrativeCommandIds.inputTextToFact && parameter.id == 'presetValues' ? 3 : 1,
          keyboardType: parameter.kind == NarrativeCommandParameterKind.number
              ? const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                )
              : parameter.kind == NarrativeCommandParameterKind.integer
              ? TextInputType.numberWithOptions(signed: _command.id == NarrativeCommandIds.adjustIntegerFact,
                )
              : null,
          errorText:
              _values[parameter.id]?.isNotEmpty == true &&
                  !_hasValidValue(parameter)
              ? '${parameter.label} est invalide.'
              : null,
          onChanged: (value) => _setValue(parameter.id, value),
        );
      default:
        if (_command.id == NarrativeCommandIds.warp &&
            parameter.kind == NarrativeCommandParameterKind.warp ||
            _command.id == NarrativeCommandIds.setMapEventInstanceBoolean &&
            parameter.kind == NarrativeCommandParameterKind.mapEntityReference) {
          if (_warpReferenceLoading) {
            return PokeMapDiagnosticCallout(
              severity: PokeMapDiagnosticSeverity.info,
              title: _command.id == NarrativeCommandIds.setMapEventInstanceBoolean
                  ? 'Chargement des éléments' : 'Chargement des points d’arrivée',
              message: 'Lecture de la carte choisie…',
            );
          }
          if (_warpReferenceError != null) {
            return PokeMapDiagnosticCallout(
              severity: PokeMapDiagnosticSeverity.error,
              title: _command.id == NarrativeCommandIds.setMapEventInstanceBoolean
                  ? 'Éléments indisponibles' : 'Points d’arrivée indisponibles',
              message: _warpReferenceError!,
              actionLabel: 'Recharger',
              onAction: () => setState(() => _loadWarpReferences()),
            );
          }
        }
        final options = _optionsFor(parameter.kind);
        final currentValue = _values[parameter.id];
        final arrivalNeedsSelection = _command.id == NarrativeCommandIds.warp &&
            parameter.kind == NarrativeCommandParameterKind.warp &&
            (currentValue == null || currentValue.isEmpty);
        if (currentValue != null &&
            currentValue.isNotEmpty &&
            !options.any((option) => option.id == currentValue)) {
          if ((_command.id == NarrativeCommandIds.givePokemonFromCatalog || _command.id == NarrativeCommandIds.receivePokemonFromCatalog) &&
              parameter.kind == NarrativeCommandParameterKind.speciesForm &&
              options.isNotEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PokeMapDiagnosticCallout(
                  key: ValueKey('scene-action-catalog-gift-form-diagnostic'),
                  severity: PokeMapDiagnosticSeverity.error,
                  title: 'Forme du cadeau à corriger',
                  message: 'La forme enregistrée ne peut pas être chargée. Choisissez la forme principale disponible.',
                ),
                const SizedBox(height: 8),
                PokeMapDropdownField<String>(
                  label: parameter.label,
                  value: '',
                  items: [
                    const PokeMapDropdownItem(value: '', label: 'Choisir la forme principale',
                    ),
                    for (final option in options)
                      PokeMapDropdownItem(value: option.id, label: option.label,
                      ),
                  ],
                  onChanged: (value) => _setReferenceValue(parameter, value),
                ),
              ],
            );
          }
          final diagnostic = PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.error,
            title: '${parameter.label} supprimé',
            message:
                'La cible « $currentValue » n’existe plus dans le '
                'catalogue du projet. Sélectionnez une cible valide avant de '
                'publier.',
          );
          final canReplaceTarget = _command.id == NarrativeCommandIds.setPlayerAvatar ||
              (_command.id == NarrativeCommandIds.adjustIntegerFact &&
                  parameter.kind == NarrativeCommandParameterKind.fact);
          if (!canReplaceTarget || options.isEmpty) {
            return diagnostic;
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              diagnostic,
              const SizedBox(height: 8),
              PokeMapDropdownField<String>(
                label: parameter.label,
                value: '',
                items: [
                  PokeMapDropdownItem(value: '', label:
                    _command.id == NarrativeCommandIds.adjustIntegerFact
                      ? 'Choisir un compteur' : 'Choisir un avatar',
                  ),
                  for (final option in options)
                    PokeMapDropdownItem(value: option.id, label: option.label),
                ],
                onChanged: (value) => _setReferenceValue(parameter, value),
              ),
            ],
          );
        }
        if (options.isEmpty) {
          return PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.warning,
            title: parameter.label,
            message:
                'Aucun ${parameter.label} disponible dans le catalogue du projet.',
          );
        }
        return PokeMapDropdownField<String>(
          label: parameter.label,
          value: arrivalNeedsSelection ? '' : currentValue ?? options.first.id,
          items: [
            if (arrivalNeedsSelection)
              const PokeMapDropdownItem(
                value: '',
                label: 'Choisir un point d’arrivée',
              ),
            for (final option in options)
              PokeMapDropdownItem(value: option.id, label: option.label),
          ],
          onChanged: (value) => _setReferenceValue(parameter, value),
        );
    }
  }

  List<SceneActionPickerOption> _optionsFor(
    NarrativeCommandParameterKind kind,
  ) {
    if (widget.project?.settings.dimension == ProjectDimension.threeD &&
        (kind == NarrativeCommandParameterKind.sceneMusicChannel || kind == NarrativeCommandParameterKind.sceneMusicScope)) {
      final supported = kind == NarrativeCommandParameterKind.sceneMusicChannel ? 'music' : 'scene';
      return [for (final option in widget.pickerOptions[kind] ?? const <SceneActionPickerOption>[]) if (option.id == supported) option];
    }
    if (kind == NarrativeCommandParameterKind.integerFacts ||
        kind == NarrativeCommandParameterKind.fact &&
            _isIntegerSceneCommand(_command.id)) {
      final facts = widget.project?.facts ?? const <NarrativeFactDefinition>[];
      return [
        for (final fact in facts)
          if (fact.valueKind == NarrativeValueKind.integer &&
              facts.where((candidate) => candidate.id == fact.id).length == 1)
            SceneActionPickerOption(id: fact.id, label: fact.label),
      ];
    }
    if (kind == NarrativeCommandParameterKind.movingProps) {
      return _loadedPropOptions ?? [for (final option in widget.pickerOptions[kind] ?? const <SceneActionPickerOption>[])
        if (option.parentId == _values['mapId']) option,
          ];
    }
    if (kind == NarrativeCommandParameterKind.mapEntityReference &&
        _command.id == NarrativeCommandIds.setMapEventInstanceBoolean) {
      return _loadedLocalOwnerOptions ?? const [];
    }
    if (kind == NarrativeCommandParameterKind.fact &&
        _command.id == NarrativeCommandIds.inputTextToFact) {
      final facts = widget.project?.facts ?? const <NarrativeFactDefinition>[];
      return [for (final fact in facts)
        if (fact.valueKind == NarrativeValueKind.string &&
            facts.where((candidate) => candidate.id == fact.id).length == 1)
          SceneActionPickerOption(id: fact.id, label: fact.label),
      ];
    }
    if (kind == NarrativeCommandParameterKind.fact &&
        _command.id == NarrativeCommandIds.adjustIntegerFact) {
      final facts = widget.project?.facts ?? const <NarrativeFactDefinition>[];
      return [for (final fact in facts)
        if (fact.valueKind == NarrativeValueKind.integer &&
            facts.where((candidate) => candidate.id == fact.id).length == 1)
          SceneActionPickerOption(id: fact.id, label: fact.label),
      ];
    }
    if (kind == NarrativeCommandParameterKind.character) {
      final project = widget.project;
      if (project == null) return const [];
      final options = <SceneActionPickerOption>[];
      for (final character in project.characters) {
        try {
          resolveScenePlayerAvatarCharacter(project, character.id);
          options.add(SceneActionPickerOption(id: character.id, label: character.name),
          );
        } on FormatException {
          continue;
        }
      }
      return options;
    }
    if ((_command.id == NarrativeCommandIds.givePokemonFromCatalog || _command.id == NarrativeCommandIds.receivePokemonFromCatalog) &&
        kind == NarrativeCommandParameterKind.species) {
      final loadableSpeciesIds = {
        for (final form in widget.pickerOptions[NarrativeCommandParameterKind.speciesForm] ?? const <SceneActionPickerOption>[])
          if (form.isPrimarySpeciesForm) form.parentId,
      };
      return [
        for (final species in widget.pickerOptions[kind] ?? const <SceneActionPickerOption>[])
          if (loadableSpeciesIds.contains(species.id)) species,
      ];
    }
    if (kind == NarrativeCommandParameterKind.map &&
        _command.id == NarrativeCommandIds.waitForActorRoutes) {
      final entries = widget.project?.maps ?? const <ProjectMapEntry>[];
      return [for (final entry in entries)
        if (entry.id.isNotEmpty && entry.id.trim() == entry.id &&
            entries.where((candidate) => candidate.id == entry.id).length == 1)
          SceneActionPickerOption(id: entry.id, label: entry.name),
      ];
    }
    if (kind == NarrativeCommandParameterKind.warp &&
        _command.id == NarrativeCommandIds.warp) {
      if (widget.loadWarpMap != null) return _loadedWarpOptions ?? const [];
      return [
        for (final option in widget.pickerOptions[kind] ?? const [])
          if (option.parentId == _values['destinationMapId']) option,
      ];
    }
    if (kind == NarrativeCommandParameterKind.speciesForm) {
      final speciesId = _values['speciesId'];
      return [
        for (final option in widget.pickerOptions[kind] ?? const [])
          if (option.parentId == speciesId &&
              ((_command.id != NarrativeCommandIds.givePokemonFromCatalog && _command.id != NarrativeCommandIds.receivePokemonFromCatalog) || option.isPrimarySpeciesForm)) option,
      ];
    }
    if (kind == NarrativeCommandParameterKind.visualElementReference) {
      final project = widget.project;
      if (project == null) return const [];
      final options = <SceneActionPickerOption>[];
      for (final element in project.elements) {
        try {
          resolveSceneWarpPresentationVisual(SceneWarpPresentation(mode: SceneWarpPresentationMode.illustrated,
            illustrationElementId: element.id,
            ),
            project,
          );
          options.add(SceneActionPickerOption(id: element.id, label: element.name),
          );
        } catch (_) {}
      }
      return options;
    }
    return switch (kind) {
      NarrativeCommandParameterKind.integerCancellationPolicy => const [SceneActionPickerOption(id: 'leaveUnchanged', label: 'Conserver le compteur et suivre Annulé'), SceneActionPickerOption(id: 'restoreInitialAndComplete', label: 'Écrire la valeur initiale et continuer')],
      NarrativeCommandParameterKind.integerOperation => [
        for (final value in SceneIntegerOperation.values)
          SceneActionPickerOption(
            id: value.name,
            label: switch (value) {
              SceneIntegerOperation.assign => 'Affecter',
              SceneIntegerOperation.add => 'Ajouter',
              SceneIntegerOperation.subtract => 'Soustraire',
              SceneIntegerOperation.multiply => 'Multiplier',
              SceneIntegerOperation.floorDivide =>
                'Diviser (arrondi inférieur)',
              SceneIntegerOperation.modulo => 'Reste de division',
            },
          ),
      ],
      NarrativeCommandParameterKind.moneyOperation => const [
        SceneActionPickerOption(id: 'add', label: 'Ajouter'),
        SceneActionPickerOption(id: 'subtract', label: 'Retirer'),
      ],
      NarrativeCommandParameterKind.integerOperandSource => [
        const SceneActionPickerOption(id: 'literal', label: 'Nombre fixe'),
        const SceneActionPickerOption(
          id: 'integerFact',
          label: 'Autre compteur',
        ),
        const SceneActionPickerOption(id: 'money', label: 'Argent du joueur'),
        const SceneActionPickerOption(
          id: 'partyCount',
          label: 'Taille de l’équipe',
        ),
        const SceneActionPickerOption(
          id: 'itemCount',
          label: 'Quantité d’un objet',
        ),
        if (_command.id == NarrativeCommandIds.calculateIntegerFacts)
          const SceneActionPickerOption(
            id: 'random',
            label: 'Tirage aléatoire sauvegardé',
          ),
      ],
      NarrativeCommandParameterKind.integerZeroPolicy => const [
        SceneActionPickerOption(id: 'reject', label: 'Refuser si nul'),
        SceneActionPickerOption(id: 'keepValue', label: 'Conserver si nul'),
        SceneActionPickerOption(
          id: 'keepValueForZeroOrOne',
          label: 'Conserver si nul ou égal à un',
        ),
      ],
      NarrativeCommandParameterKind.integerBoundaryPolicy => const [
        SceneActionPickerOption(id: 'clamp', label: 'Limiter le résultat'),
        SceneActionPickerOption(
          id: 'preserveSaturated',
          label: 'Conserver un compteur déjà à la limite',
        ),
      ],
      NarrativeCommandParameterKind.movingPropState => const [
        SceneActionPickerOption(id: 'open', label: 'Ouvert'),
        SceneActionPickerOption(id: 'closed', label: 'Fermé'),
      ],
      NarrativeCommandParameterKind.pokemonGiftNicknamePolicy => const [
        SceneActionPickerOption(id: 'offer', label: 'Proposer un surnom'),
        SceneActionPickerOption(id: 'disabled', label: 'Conserver le nom de l’espèce',
        ),
      ],
      NarrativeCommandParameterKind.pokemonGiftPokedexPolicy => const [
        SceneActionPickerOption(id: 'never', label: 'Ne pas ouvrir de fiche'),
        SceneActionPickerOption(id: 'whenNewAndPokedexVisible', label: 'Nouvelle espèce si le Pokédex est visible',
        ),
      ],
      NarrativeCommandParameterKind.completionOutcome => const [
        SceneActionPickerOption(id: 'completed', label: 'Partie terminée'),
        SceneActionPickerOption(id: 'victory', label: 'Victoire'),
        SceneActionPickerOption(
          id: 'alternateEnding',
          label: 'Fin alternative',
        ),
      ],
      NarrativeCommandParameterKind.postGamePolicy => const [
        SceneActionPickerOption(
          id: 'continueGame',
          label: 'Continuer en postgame',
        ),
        SceneActionPickerOption(
          id: 'returnToTitle',
          label: 'Retourner au titre',
        ),
        SceneActionPickerOption(id: 'returnToHub', label: 'Retourner au Hub'),
      ],
      NarrativeCommandParameterKind.movingPlatformMotion => const [
        SceneActionPickerOption(id: 'forward', label: 'Avancer'),
        SceneActionPickerOption(id: 'backward', label: 'Reculer'),
        SceneActionPickerOption(
          id: 'rotateClockwise',
          label: 'Tourner vers la droite',
        ),
      ],
      NarrativeCommandParameterKind.characterDirection => [
        if (_command.id == NarrativeCommandIds.warp || _command.id == NarrativeCommandIds.setNpcPose && _npcPosePosition)
          const SceneActionPickerOption(
            id: '',
            label: 'Conserver la direction',
          ),
        const SceneActionPickerOption(id: 'south', label: 'Sud'),
        const SceneActionPickerOption(id: 'north', label: 'Nord'),
        const SceneActionPickerOption(id: 'east', label: 'Est'),
        const SceneActionPickerOption(id: 'west', label: 'Ouest'),
      ],
      NarrativeCommandParameterKind.warpPresentationMode => const [
        SceneActionPickerOption(id: '', label: 'Transition habituelle'),
        SceneActionPickerOption(id: 'fade', label: 'Fondu noir'),
        SceneActionPickerOption(id: 'illustrated', label: 'Illustration du lieu',
        ),
        SceneActionPickerOption(id: 'caveEntrance', label: 'Entrée de grotte'),
        SceneActionPickerOption(id: 'caveExit', label: 'Sortie de grotte'),
      ],
      NarrativeCommandParameterKind.warpTransition => const [
        SceneActionPickerOption(
          id: 'mapDefault',
          label: 'Transition de la carte',
        ),
        SceneActionPickerOption(id: 'none', label: 'Sans transition'),
      ],
      NarrativeCommandParameterKind.customAnimationPlayback => const [
        SceneActionPickerOption(id: 'once', label: 'Une fois'),
        SceneActionPickerOption(
          id: 'repeatCount',
          label: 'Nombre de répétitions',
        ),
        SceneActionPickerOption(id: 'forDuration', label: 'Pendant une durée'),
      ],
      NarrativeCommandParameterKind.pauseMenuAction => const [
        SceneActionPickerOption(id: 'party', label: 'Équipe'),
        SceneActionPickerOption(id: 'bag', label: 'Sac'),
        SceneActionPickerOption(id: 'pokedex', label: 'Pokédex'),
        SceneActionPickerOption(id: 'map', label: 'Carte'),
        SceneActionPickerOption(id: 'save', label: 'Sauvegarder'),
        SceneActionPickerOption(id: 'options', label: 'Options'),
        SceneActionPickerOption(id: 'returnToTitle', label: 'Retour au titre'),
      ],
      NarrativeCommandParameterKind.railJourneyOperation => const [
        SceneActionPickerOption(id: 'begin', label: 'Départ'),
        SceneActionPickerOption(id: 'advance', label: 'Progression'),
        SceneActionPickerOption(id: 'acknowledge', label: 'Confirmation'),
      ],
      NarrativeCommandParameterKind.railJourneyDirection => const [
        SceneActionPickerOption(id: 'outbound', label: 'Aller'),
        SceneActionPickerOption(id: 'return', label: 'Retour'),
      ],
      NarrativeCommandParameterKind.railJourneyAdvanceEvent => const [
        SceneActionPickerOption(id: 'doorsClosed', label: 'Portes fermées'),
        SceneActionPickerOption(id: 'arrivalReached', label: 'Arrivée'),
        SceneActionPickerOption(
          id: 'destinationDoorUsed',
          label: 'Porte de destination',
        ),
      ],
      NarrativeCommandParameterKind.railJourneyDoorSide => const [
        SceneActionPickerOption(id: 'west', label: 'Porte ouest'),
        SceneActionPickerOption(id: 'east', label: 'Porte est'),
      ],
      _ => widget.pickerOptions[kind] ?? const [],
    };
  }

  void _setValue(String parameterId, String value) {
    setState(() {
      _values[parameterId] = value;
      _submissionError = null;
    });
  }

  void _setReferenceValue(
    NarrativeCommandParameterDescriptor parameter,
    String value,
  ) {
    setState(() {
      _values[parameter.id] = value;
      if (_command.id == NarrativeCommandIds.sceneMusic && parameter.id == 'operation') _syncMusicOperation();
      if (_command.id == NarrativeCommandIds.warp && parameter.id == 'presentationMode') {
        if (value != 'illustrated' && value != 'caveEntrance') {
          for (final key in ['illustrationElementId', 'illustrationHoldMs', 'illustrationFadeMs',
          ]) {
            _values.remove(key); _textControllers[key]?.text = '';
          }
        }
        if (value.isEmpty) {
          for (final key in ['fadeOutMs', 'transferDelayMs', 'revealMs']) {
            _values.remove(key); _textControllers[key]?.text = '';
          }
        }
      }
      _applyOptionParameters(parameter.kind, value);
      if (_command.id == NarrativeCommandIds.setMapEventInstanceBoolean && parameter.id == 'mapId') {
        _values.remove('eventId');
        _loadWarpReferences();
      }
      if (_command.id == NarrativeCommandIds.setPropState && parameter.id == 'mapId') {
        _values['propIds'] = '[]';
        _loadWarpReferences();
      }
      if (_command.id == NarrativeCommandIds.warp &&
          parameter.id == 'destinationMapId') {
        _values.remove('warpId');
        _loadWarpReferences();
      }
      if (parameter.kind == NarrativeCommandParameterKind.species) {
        final options = _optionsFor(NarrativeCommandParameterKind.speciesForm);
        final selectedFormId = _values['formId'];
        if (!options.any((option) => option.id == selectedFormId)) {
          if (options.isEmpty) {
            _values.remove('formId');
          } else {
            _values['formId'] = options.first.id;
          }
        }
      }
      _submissionError = null;
    });
  }

  void _applyOptionParameters(
    NarrativeCommandParameterKind kind,
    String optionId,
  ) {
    final options = _optionsFor(kind);
    final parameterKeys = <String>{
      for (final option in options) ...option.parameters.keys,
    };
    for (final key in parameterKeys) {
      _values.remove(key);
    }
    for (final option in options) {
      if (option.id == optionId) {
        _values.addAll(option.parameters);
        return;
      }
    }
  }

  void _submit() {
    try {
      final parameters = Map<String, String>.unmodifiable(_values);
      var payload = buildScenePayloadForNarrativeCommand(
        commandId: _command.id,
        parameters: parameters,
      );
      final previousTrade = widget.initialPayload?.interactiveCommand;
      if (_command.id == NarrativeCommandIds.openNpcTrade && previousTrade is SceneOpenPartyTradeInteractiveCommand && previousTrade.npcOffer != null && payload is SceneActionPayload) {
        final fresh = (payload.interactiveCommand as SceneOpenPartyTradeInteractiveCommand).npcOffer!;
        final previous = previousTrade.npcOffer!;
        if (previous.offeredPokemon.speciesId == fresh.offeredPokemon.speciesId && previous.offeredPokemon.formId == fresh.offeredPokemon.formId) {
          payload = SceneActionPayload.interactive(SceneInteractiveCommand.openPartyTrade(npcOffer: NpcPokemonTradeOffer(
            id: fresh.id, requestedSpeciesId: fresh.requestedSpeciesId, matchSelectedLevel: fresh.matchSelectedLevel,
            offeredPokemon: previous.offeredPokemon.copyWith(nickname: fresh.offeredPokemon.nickname, level: fresh.offeredPokemon.level))));
        }
      }
      final previousPayload = widget.initialPayload;
      final previousFinish = previousPayload?.consequence;
      if (_command.id == NarrativeCommandIds.finishGame &&
          previousPayload != null && previousFinish is SceneFinishGameConsequence) {
        payload = SceneActionPayload(
          actionKind: previousPayload.actionKind,
          parameters: previousPayload.parameters,
          consequence: updateSceneFinishGameAuthoringParameters(
              previousFinish, parameters),
          preSessionInteraction: previousPayload.preSessionInteraction,
        );
      }
      final original = widget.initialPayload?.interactiveCommand;
      if (original is SceneInputIntegerToFactInteractiveCommand && payload is SceneActionPayload &&
          payload.interactiveCommand is SceneInputIntegerToFactInteractiveCommand) {
        final fresh = payload.interactiveCommand! as SceneInputIntegerToFactInteractiveCommand;
        payload = SceneActionPayload.interactive(SceneInteractiveCommand.fromJson({...fresh.toJson(),
          'prompt': {...original.prompt.toJson(), 'fallbackText': fresh.prompt.fallbackText}}));
      }
      if (original is SceneTryPayMoneyInteractiveCommand && payload is SceneActionPayload &&
          payload.interactiveCommand is SceneTryPayMoneyInteractiveCommand) {
        final fresh = payload.interactiveCommand! as SceneTryPayMoneyInteractiveCommand;
        if (original.confirmationPrompt != null && fresh.confirmationPrompt != null) {
          payload = SceneActionPayload.interactive(SceneInteractiveCommand.fromJson({...fresh.toJson(),
            'confirmationPrompt': {...original.confirmationPrompt!.toJson(), 'fallbackText': fresh.confirmationPrompt!.fallbackText}}));
        }
      }
      if (original is SceneInputTextToFactInteractiveCommand &&
          payload is SceneActionPayload &&
          payload.interactiveCommand is SceneInputTextToFactInteractiveCommand) {
        final fresh = payload.interactiveCommand! as SceneInputTextToFactInteractiveCommand;
        payload = SceneActionPayload.interactive(SceneInteractiveCommand.fromJson({
          ...fresh.toJson(),
          'prompt': {...original.prompt.toJson(), 'fallbackText': fresh.prompt.fallbackText,
            },
          'confirmationPrompt': {...original.confirmationPrompt.toJson(), 'fallbackText': fresh.confirmationPrompt.fallbackText,
            },
          if (fresh.presetChoicePrompt != null && original.presetChoicePrompt != null)
            'presetChoicePrompt': {...original.presetChoicePrompt!.toJson(), 'fallbackText': fresh.presetChoicePrompt!.fallbackText,
              },
          }),
        );
      }
      widget.onSubmitResult?.call(
        SceneActionBuildResult(
          command: _command,
          payload: payload,
          parameters: parameters,
        ),
      );
      widget.onSubmit(payload);
    } on Object catch (error) {
      setState(() => _submissionError = error.toString());
    }
  }
}

Object? _integerStoredParameter(Map<String, dynamic> data, String id) {
  final operand = data['operand'] ?? data['amount'];
  if (operand is Map) {
    if (id == 'operandSource') {
      return operand['kind'] == 'gameRead' ? operand['read'] : operand['kind'];
    }
    if (id == 'operandValue') return operand['value'];
    if (id == 'operandFactId') return operand['factId'];
    if (id == 'operandItemId') return operand['itemId'];
    if (id == 'randomMinimum') return operand['minimum'];
    if (id == 'randomMaximum') return operand['maximum'];
  }
  final value = data[id];
  if (value is Map && (id == 'prompt' || id == 'confirmationPrompt')) {
    return value['fallbackText'];
  }
  return value;
}
