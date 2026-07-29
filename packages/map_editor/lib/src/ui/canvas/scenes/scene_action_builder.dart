import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../application/services/narrative_template_catalog.dart';
import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';
import 'scene_action_inspector.dart';

final class SceneActionPickerOption {
  const SceneActionPickerOption({
    required this.id,
    required this.label,
    this.parameters = const {},
  });

  final String id;
  final String label;
  final Map<String, String> parameters;
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

  @override
  State<SceneActionBuilder> createState() => _SceneActionBuilderState();
}

class _SceneActionBuilderState extends State<SceneActionBuilder> {
  late final NarrativeCommandCatalog _catalog;
  late String _commandId;
  final Map<String, String> _values = <String, String>{};
  final Map<String, TextEditingController> _textControllers = {};
  String? _submissionError;

  @override
  void initState() {
    super.initState();
    _catalog = widget.commandCatalog ?? NarrativeCommandCatalog.canonical();
    _commandId = _initialCommandId();
    _seedParameterValues(_command);
  }

  NarrativeCommandDescriptor get _command => _catalog.byId(_commandId)!;

  List<NarrativeCommandDescriptor> get _availableCommands => [
        for (final command in _catalog.commands)
          if (command.capabilities.editor ==
                  NarrativeCommandCapabilityStatus.supported &&
              _runtimeAllows(command))
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
    final requested = widget.initialCommandId;
    if (requested != null &&
        _availableCommands.any((command) => command.id == requested)) {
      return requested;
    }
    return _availableCommands.first.id;
  }

  void _seedParameterValues(NarrativeCommandDescriptor command) {
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    _textControllers.clear();
    _values.clear();
    for (final parameter in command.parameters) {
      final initial = widget.initialParameters[parameter.id];
      switch (parameter.kind) {
        case NarrativeCommandParameterKind.boolean:
          _values[parameter.id] = initial == 'false' ? 'false' : 'true';
        case NarrativeCommandParameterKind.integer:
          final value = initial ?? '1';
          _values[parameter.id] = value;
          _textControllers[parameter.id] = TextEditingController(text: value);
        case NarrativeCommandParameterKind.text:
          final value = initial ?? '';
          _values[parameter.id] = value;
          _textControllers[parameter.id] = TextEditingController(text: value);
        default:
          final options = _optionsFor(parameter.kind);
          if (initial?.trim().isNotEmpty == true) {
            _values[parameter.id] = initial!.trim();
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
  }

  @override
  void dispose() {
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  List<NarrativeCommandParameterDescriptor> get _missingParameters => [
        for (final parameter in _command.parameters)
          if (_isParameterVisible(parameter) &&
              _isParameterRequired(parameter) &&
              !_hasValidValue(parameter))
            parameter,
      ];

  bool _isParameterRequired(NarrativeCommandParameterDescriptor parameter) {
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
    if (_command.id != NarrativeCommandIds.finishGame) return true;
    if (!parameter.id.startsWith('credits') ||
        parameter.id == 'includeCredits') {
      return true;
    }
    return _values['includeCredits'] == 'true';
  }

  bool _hasValidValue(NarrativeCommandParameterDescriptor parameter) {
    final value = _values[parameter.id]?.trim();
    if (value == null || value.isEmpty) return false;
    if (parameter.kind == NarrativeCommandParameterKind.integer) {
      final parsed = int.tryParse(value);
      return parsed != null && parsed > 0;
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
      parameter.kind != NarrativeCommandParameterKind.text;

  bool get _canSubmit =>
      _command.capabilities.editor ==
          NarrativeCommandCapabilityStatus.supported &&
      _runtimeAllows(_command) &&
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
      footer: Padding(
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
          SceneActionInspector(
            command: _command,
            missingParameterLabels:
                _missingParameters.map((parameter) => parameter.label).toList(),
          ),
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
          items: const [
            PokeMapDropdownItem(value: 'true', label: 'Vrai'),
            PokeMapDropdownItem(value: 'false', label: 'Faux'),
          ],
          onChanged: (value) => _setReferenceValue(parameter, value),
        );
      case NarrativeCommandParameterKind.integer:
      case NarrativeCommandParameterKind.text:
        return PokeMapTextField(
          label: parameter.label,
          fieldKey: ValueKey('scene-action-parameter-${parameter.id}'),
          controller: _textControllers[parameter.id],
          keyboardType: parameter.kind == NarrativeCommandParameterKind.integer
              ? TextInputType.number
              : null,
          errorText: _values[parameter.id]?.isNotEmpty == true &&
                  !_hasValidValue(parameter)
              ? '${parameter.label} est invalide.'
              : null,
          onChanged: (value) => _setValue(parameter.id, value),
        );
      default:
        final options = _optionsFor(parameter.kind);
        final currentValue = _values[parameter.id];
        if (currentValue != null &&
            currentValue.isNotEmpty &&
            !options.any((option) => option.id == currentValue)) {
          return PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.error,
            title: '${parameter.label} supprimé',
            message: 'La cible « $currentValue » n’existe plus dans le '
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
          value: currentValue ?? options.first.id,
          items: [
            for (final option in options)
              PokeMapDropdownItem(value: option.id, label: option.label),
          ],
          onChanged: (value) => _setValue(parameter.id, value),
        );
    }
  }

  List<SceneActionPickerOption> _optionsFor(
    NarrativeCommandParameterKind kind,
  ) {
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
          SceneActionPickerOption(
            id: 'returnToHub',
            label: 'Retourner au Hub',
          ),
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
