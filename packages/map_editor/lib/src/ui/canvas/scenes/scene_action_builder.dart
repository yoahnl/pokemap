import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';
import 'scene_action_inspector.dart';
import 'scene_actor_action_builder.dart';

final class SceneActionPickerOption {
  const SceneActionPickerOption({
    required this.id,
    required this.label,
    this.parentId,
    this.parameters = const {},
  });

  final String id;
  final String label;
  final String? parentId;
  final Map<String, String> parameters;
}

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
  String? _warpReferenceError;
  bool _warpReferenceLoading = false;
  int _warpReferenceRequest = 0;

  @override
  void initState() {
    super.initState();
    _catalog = widget.commandCatalog ?? NarrativeCommandCatalog.canonical();
    _commandId = _initialCommandId();
    _seedParameterValues(_command);
  }

  NarrativeCommandDescriptor get _command => _catalog.byId(_commandId)!;

  bool _is2DPresentationCommand(String id) =>
      id == NarrativeCommandIds.openRegionalMap ||
      id == NarrativeCommandIds.openPartyTrade ||
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
      return runtimeCommandIds.contains(command.id);
    }
    return command.capabilities.runtime ==
        NarrativeCommandCapabilityStatus.supported;
  }

  String _initialCommandId() {
    final requested =
        widget.initialCommandId ??
        widget.initialPayload?.interactiveCommand?.kind.name;
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
    for (final parameter in command.parameters) {
      final existing = widget.initialPayload?.interactiveCommand;
      final storedValue = _is2DPresentationCommand(command.id) &&
              existing?.kind.name == command.id
          ? existing!.toJson()[parameter.id]
          : null;
      final initial = widget.initialParameters[parameter.id] ??
          (storedValue is String || storedValue is num ? '$storedValue' : null);
      switch (parameter.kind) {
        case NarrativeCommandParameterKind.boolean:
          _values[parameter.id] = initial == 'false' ? 'false' : 'true';
        case NarrativeCommandParameterKind.integer:
          final value =
              initial ??
              ((command.id == NarrativeCommandIds.worldTone ||
                       command.id == NarrativeCommandIds.wait) &&
                      parameter.id == 'durationMs'
                  ? '0'
                  : '1');
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
        default:
          final options = _optionsFor(parameter.kind);
          final strictWarpOption = command.id == NarrativeCommandIds.warp &&
              (parameter.id == 'arrivalFacing' || parameter.id == 'transition');
          if (initial != null &&
              (initial.trim().isNotEmpty || strictWarpOption && initial.isNotEmpty)) {
            _values[parameter.id] = strictWarpOption ? initial : initial.trim();
          } else if (options.isNotEmpty) {
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
    _loadWarpReferences(selectFirst: true);
  }

  @override
  void didUpdateWidget(SceneActionBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loadWarpMap != widget.loadWarpMap ||
        oldWidget.pickerOptions != widget.pickerOptions) {
      _loadWarpReferences();
    }
  }

  void _loadWarpReferences({bool selectFirst = false}) {
    final request = ++_warpReferenceRequest;
    _loadedWarpOptions = null;
    _warpReferenceError = null;
    _warpReferenceLoading = false;
    final load = widget.loadWarpMap;
    final mapId = _values['destinationMapId'];
    if (_command.id != NarrativeCommandIds.warp ||
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
    final rawValue = _values[parameter.id];
    final value = rawValue?.trim();
    if (_command.id == NarrativeCommandIds.warp &&
        (parameter.id == 'arrivalFacing' || parameter.id == 'transition') &&
        rawValue != value) {
      return false;
    }
    if (value == null || value.isEmpty) return false;
    if (parameter.kind == NarrativeCommandParameterKind.integer) {
      if ((_command.id == NarrativeCommandIds.worldTone ||
           _command.id == NarrativeCommandIds.wait) &&
          parameter.id == 'durationMs') {
        return _hasValidPresentationParameter(parameter.id, value);
      }
      final parsed = int.tryParse(value);
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

  bool get _canSubmit =>
      _command.capabilities.editor ==
          NarrativeCommandCapabilityStatus.supported &&
      _runtimeAllows(_command) &&
      (!_is2DPresentationCommand(_command.id) ||
          widget.project?.settings.dimension == ProjectDimension.twoD) &&
      (_command.id != NarrativeCommandIds.warp ||
          !_warpReferenceLoading && _warpReferenceError == null) &&
      _missingParameters.isEmpty;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapPanel(
      header: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          'Ajouter une action',
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
                  child: const Text('Ajouter à la Scene'),
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
          keyboardType: parameter.kind == NarrativeCommandParameterKind.number
              ? const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                )
              : parameter.kind == NarrativeCommandParameterKind.integer
              ? TextInputType.number
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
            parameter.kind == NarrativeCommandParameterKind.warp) {
          if (_warpReferenceLoading) {
            return const PokeMapDiagnosticCallout(
              severity: PokeMapDiagnosticSeverity.info,
              title: 'Chargement des points d’arrivée',
              message: 'Lecture de la carte de destination…',
            );
          }
          if (_warpReferenceError != null) {
            return PokeMapDiagnosticCallout(
              severity: PokeMapDiagnosticSeverity.error,
              title: 'Points d’arrivée indisponibles',
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
          return PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.error,
            title: '${parameter.label} supprimé',
            message:
                'La cible « $currentValue » n’existe plus dans le '
                'catalogue du projet. Sélectionnez une cible valide avant de '
                'publier.',
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
    if (kind == NarrativeCommandParameterKind.map &&
        _command.id == NarrativeCommandIds.waitForActorRoutes) {
      final entries = widget.project?.maps ?? const <ProjectMapEntry>[];
      return [for (final entry in entries)
        if (entry.id.isNotEmpty && entry.id.trim() == entry.id &&
            entries.where((candidate) => candidate.id == entry.id).length == 1)
          SceneActionPickerOption(id: entry.id, label: entry.name)];
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
          if (option.parentId == speciesId) option,
      ];
    }
    return switch (kind) {
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
        if (_command.id == NarrativeCommandIds.warp)
          const SceneActionPickerOption(
            id: '',
            label: 'Conserver la direction',
          ),
        const SceneActionPickerOption(id: 'south', label: 'Sud'),
        const SceneActionPickerOption(id: 'north', label: 'Nord'),
        const SceneActionPickerOption(id: 'east', label: 'Est'),
        const SceneActionPickerOption(id: 'west', label: 'Ouest'),
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
      _applyOptionParameters(parameter.kind, value);
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
      final payload = buildScenePayloadForNarrativeCommand(
        commandId: _command.id,
        parameters: parameters,
      );
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
