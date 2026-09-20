import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/feedback/studio_notice.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_draft_field.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_toggle_row.dart';

class SceneActionForm extends StatefulWidget {
  const SceneActionForm({
    super.key,
    required this.project,
    required this.current,
    required this.onApply,
  });

  final ProjectManifest project;
  final SceneNodePayload? current;
  final ValueChanged<SceneNodePayload> onApply;

  @override
  State<SceneActionForm> createState() => _SceneActionFormState();
}

class _SceneActionFormState extends State<SceneActionForm> {
  final _commands = [
    for (final command in NarrativeCommandCatalog.canonical().commands)
      if (command.isPublishable &&
          command.backend != NarrativeCommandBackend.dedicatedSceneNode)
        command,
  ];
  final _values = <String, String>{};
  String? _commandId;
  bool _unsupported = false;
  String? _error;

  NarrativeCommandDescriptor? get _command =>
      _commands.where((command) => command.id == _commandId).firstOrNull;

  @override
  void initState() {
    super.initState();
    _readCurrent();
  }

  @override
  void didUpdateWidget(SceneActionForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current != widget.current) _readCurrent();
  }

  void _readCurrent() {
    _values.clear();
    _error = null;
    _commandId = null;
    final current = widget.current;
    _unsupported = current != null;
    if (current == null) return;
    if (current is! SceneActionPayload) return;
    final data =
        current.consequence?.toJson() ?? current.interactiveCommand?.toJson();
    _commandId =
        current.consequence?.kind.name ?? current.interactiveCommand?.kind.name;
    if (_command == null || data == null) {
      _commandId = null;
      return;
    }
    for (final parameter in _command!.parameters) {
      final value = data[parameter.id];
      if (value is String || value is num || value is bool) {
        _values[parameter.id] = '$value';
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
  }

  SceneNodePayload _buildPayload() {
    final built = buildScenePayloadForNarrativeCommand(
      commandId: _commandId!,
      parameters: _values,
    );
    final original = widget.current;
    if (built is SceneActionPayload && original is SceneActionPayload) {
      return SceneActionPayload(
        actionKind: original.actionKind,
        parameters: original.parameters,
        consequence: built.consequence,
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
      if (parameter.kind == NarrativeCommandParameterKind.boolean) {
        _values[parameter.id] = 'true';
      } else if (parameter.kind == NarrativeCommandParameterKind.integer &&
          parameter.required) {
        _values[parameter.id] = '1';
      }
    }
  });

  bool get _valid {
    final command = _command;
    if (command == null) return false;
    for (final parameter in command.parameters) {
      final value = _values[parameter.id];
      if (value == null || value.trim().isEmpty) {
        if (parameter.required) return false;
        continue;
      }
      if (parameter.kind == NarrativeCommandParameterKind.integer) {
        if (int.tryParse(value) == null) return false;
      } else if (parameter.kind != NarrativeCommandParameterKind.text &&
          parameter.kind != NarrativeCommandParameterKind.boolean &&
          !_options(parameter.kind).containsKey(value)) {
        return false;
      }
    }
    return true;
  }

  Map<String, String> _options(
    NarrativeCommandParameterKind kind,
  ) => switch (kind) {
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
      for (final map in widget.project.maps) map.id: map.name,
    },
    NarrativeCommandParameterKind.shop => {
      for (final shop in widget.project.shops) shop.id: shop.label,
    },
    NarrativeCommandParameterKind.badge => {
      for (final badge in widget.project.badges) badge.id: badge.label,
    },
    NarrativeCommandParameterKind.fieldAbility => const {
      'surf': 'Surf',
      'cut': 'Coupe',
      'strength': 'Force',
      'flash': 'Flash',
      'rock_smash': 'Éclate-Roc',
      'waterfall': 'Cascade',
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
      for (final parameter
          in _command?.parameters ?? <NarrativeCommandParameterDescriptor>[])
        Padding(
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
                  setState(() => _error = 'Paramètres incompatibles : $error');
                }
              },
      ),
    ],
  );

  Widget _field(NarrativeCommandParameterDescriptor parameter) {
    void changed(String value) => setState(() {
      _values[parameter.id] = value;
      _error = null;
    });
    if (parameter.kind == NarrativeCommandParameterKind.boolean) {
      return StudioToggleRow(
        label: parameter.label,
        value: _values[parameter.id] == 'true',
        onChanged: (value) => changed('$value'),
      );
    }
    if (parameter.kind == NarrativeCommandParameterKind.integer ||
        parameter.kind == NarrativeCommandParameterKind.text) {
      return StudioDraftField(
        key: ValueKey('action-$_commandId-${parameter.id}'),
        label: parameter.label,
        value: _values[parameter.id] ?? '',
        onChanged: changed,
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
}
