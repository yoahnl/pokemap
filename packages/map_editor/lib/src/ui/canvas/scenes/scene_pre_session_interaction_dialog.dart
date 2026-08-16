import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme;
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

final class ScenePreSessionInteractionCueOption {
  const ScenePreSessionInteractionCueOption({
    required this.presentationNodeId,
    required this.markerId,
    required this.label,
  });

  final String presentationNodeId;
  final String markerId;
  final String label;

  String get value => '$presentationNodeId::$markerId';
}

final class ScenePreSessionInteractionDraft {
  const ScenePreSessionInteractionDraft({
    required this.title,
    required this.interaction,
    this.cueBinding,
  });

  final String title;
  final ScenePreSessionInteractionSpec interaction;
  final ScenePreSessionInteractionCueOption? cueBinding;
}

List<ScenePreSessionInteractionCueOption>
buildScenePreSessionInteractionCueOptions({
  required SceneGraph graph,
  required List<PresentationCinematicAsset> cinematics,
}) {
  final cinematicsById = <String, PresentationCinematicAsset>{
    for (final cinematic in cinematics) cinematic.id: cinematic,
  };
  final options = <ScenePreSessionInteractionCueOption>[];
  for (final node in graph.nodes) {
    final payload = node.payload;
    if (payload is! ScenePresentationCinematicPayload) continue;
    final cinematic = cinematicsById[payload.presentationCinematicId];
    if (cinematic == null) continue;
    for (final track in cinematic.tracks) {
      for (final clip in track.clips) {
        if (clip is! PresentationMarkerClip ||
            clip.markerKind != PresentationMarkerKind.interactionCue) {
          continue;
        }
        options.add(
          ScenePreSessionInteractionCueOption(
            presentationNodeId: node.id,
            markerId: clip.id,
            label:
                '${node.title ?? cinematic.title} · ${clip.label} '
                '(${_formatTime(clip.startUs)})',
          ),
        );
      }
    }
  }
  options.sort((left, right) => left.label.compareTo(right.label));
  return List<ScenePreSessionInteractionCueOption>.unmodifiable(options);
}

Future<ScenePreSessionInteractionDraft?> showScenePreSessionInteractionEditor({
  required BuildContext context,
  required SceneInteractionRequestKind kind,
  required ProjectNewGameConfig newGameConfig,
  required List<ScenePreSessionInteractionCueOption> cueOptions,
  ScenePreSessionInteractionSpec? initialInteraction,
  String? initialTitle,
  ScenePreSessionInteractionCueOption? initialCueBinding,
}) => showPokeMapDesktopSideSheet<ScenePreSessionInteractionDraft>(
  context: context,
  title: initialInteraction == null
      ? 'Ajouter ${scenePreSessionInteractionKindLabel(kind)}'
      : 'Modifier ${scenePreSessionInteractionKindLabel(kind)}',
  semanticLabel:
      'Éditeur sans code ${scenePreSessionInteractionKindLabel(kind)}',
  barrierLabel: 'Fermer l’éditeur d’interaction',
  width: 760,
  builder: (context) => ScenePreSessionInteractionEditor(
    kind: kind,
    newGameConfig: newGameConfig,
    cueOptions: cueOptions,
    initialInteraction: initialInteraction,
    initialTitle: initialTitle,
    initialCueBinding: initialCueBinding,
  ),
);

String scenePreSessionInteractionKindLabel(SceneInteractionRequestKind kind) =>
    switch (kind) {
      SceneInteractionRequestKind.message => 'Message',
      SceneInteractionRequestKind.text => 'Saisie',
      SceneInteractionRequestKind.choice => 'Choix',
      SceneInteractionRequestKind.confirmation => 'Confirmation',
      SceneInteractionRequestKind.selection => 'Sélection',
    };

class ScenePreSessionInteractionEditor extends StatefulWidget {
  const ScenePreSessionInteractionEditor({
    super.key,
    required this.kind,
    required this.newGameConfig,
    required this.cueOptions,
    this.initialInteraction,
    this.initialTitle,
    this.initialCueBinding,
  });

  final SceneInteractionRequestKind kind;
  final ProjectNewGameConfig newGameConfig;
  final List<ScenePreSessionInteractionCueOption> cueOptions;
  final ScenePreSessionInteractionSpec? initialInteraction;
  final String? initialTitle;
  final ScenePreSessionInteractionCueOption? initialCueBinding;

  @override
  State<ScenePreSessionInteractionEditor> createState() =>
      _ScenePreSessionInteractionEditorState();
}

class _ScenePreSessionInteractionEditorState
    extends State<ScenePreSessionInteractionEditor> {
  late final TextEditingController _titleController;
  late final TextEditingController _promptController;
  late final TextEditingController _localizationController;
  late final TextEditingController _optionsController;
  late final TextEditingController _minimumController;
  late final TextEditingController _maximumController;
  late String _binding;
  late String _cue;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialInteraction;
    _titleController = TextEditingController(
      text:
          widget.initialTitle ??
          scenePreSessionInteractionKindLabel(widget.kind),
    );
    _promptController = TextEditingController(
      text: initial?.prompt.fallbackText ?? '',
    );
    _localizationController = TextEditingController(
      text: initial?.prompt.localizationKey ?? '',
    );
    _optionsController = TextEditingController(
      text:
          initial?.options
              .map((option) => option.label.fallbackText ?? option.id)
              .join('\n') ??
          '',
    );
    _minimumController = TextEditingController(
      text: switch (widget.kind) {
        SceneInteractionRequestKind.text =>
          '${initial?.textConstraints?.minGraphemes ?? 0}',
        SceneInteractionRequestKind.selection =>
          '${initial?.selectionConstraints?.minSelections ?? 1}',
        _ => '',
      },
    );
    _maximumController = TextEditingController(
      text: switch (widget.kind) {
        SceneInteractionRequestKind.text =>
          '${initial?.textConstraints?.maxGraphemes ?? 48}',
        SceneInteractionRequestKind.selection =>
          '${initial?.selectionConstraints?.maxSelections ?? 1}',
        _ => '',
      },
    );
    _binding = initial?.resultBinding?.field.name ?? '';
    _cue = widget.initialCueBinding?.value ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _promptController.dispose();
    _localizationController.dispose();
    _optionsController.dispose();
    _minimumController.dispose();
    _maximumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final interaction = _tryBuildInteraction();
    return ListView(
      key: const ValueKey('scene-pre-session-interaction-editor'),
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          scenePreSessionInteractionKindLabel(widget.kind),
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Ce bloc appartient à Scene et utilise exactement le contrat du Player.',
          style: TextStyle(color: colors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 16),
        PokeMapTextField(
          label: 'Nom du bloc',
          fieldKey: const ValueKey('scene-interaction-title'),
          controller: _titleController,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        PokeMapTextField(
          label: 'Texte affiché',
          fieldKey: const ValueKey('scene-interaction-prompt'),
          controller: _promptController,
          minLines: 2,
          maxLines: 4,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        PokeMapTextField(
          label: 'Clé de traduction facultative',
          fieldKey: const ValueKey('scene-interaction-localization-key'),
          controller: _localizationController,
          hintText: 'Générée automatiquement si elle reste vide',
          onChanged: (_) => setState(() {}),
        ),
        if (_supportsOptions) ...[
          const SizedBox(height: 12),
          PokeMapTextField(
            label: _usesConfiguredOptions
                ? 'Options issues de Nouvelle partie'
                : 'Options, une par ligne',
            fieldKey: const ValueKey('scene-interaction-options'),
            controller: _optionsController,
            enabled: !_usesConfiguredOptions,
            minLines: 3,
            maxLines: 6,
            onChanged: (_) => setState(() {}),
          ),
        ],
        if (_supportsConstraints) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: PokeMapTextField(
                  label: widget.kind == SceneInteractionRequestKind.text
                      ? 'Caractères minimum'
                      : 'Sélections minimum',
                  fieldKey: const ValueKey('scene-interaction-minimum'),
                  controller: _minimumController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PokeMapTextField(
                  label: widget.kind == SceneInteractionRequestKind.text
                      ? 'Caractères maximum'
                      : 'Sélections maximum',
                  fieldKey: const ValueKey('scene-interaction-maximum'),
                  controller: _maximumController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  enabled: !_usesScalarBinding,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ],
        if (_bindingItems.length > 1) ...[
          const SizedBox(height: 12),
          PokeMapDropdownField<String>(
            key: const ValueKey('scene-interaction-binding'),
            label: 'Enregistrer le résultat dans',
            value: _binding,
            items: _bindingItems,
            onChanged: (value) {
              setState(() {
                _binding = value;
                if (_usesConfiguredOptions) {
                  _optionsController.text = _configuredOptions
                      .map((option) => option.label.fallbackText ?? option.id)
                      .join('\n');
                }
                if (_usesScalarBinding) _maximumController.text = '1';
              });
            },
          ),
        ],
        if (interaction != null) ...[
          const SizedBox(height: 12),
          Text(
            'Sorties Scene',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            key: const ValueKey('scene-interaction-output-ports'),
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final outputPortId in interaction.outputPortIds)
                PokeMapBadge(
                  label: _outputPortLabel(outputPortId),
                  variant: PokeMapBadgeVariant.narrative,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Chaque sortie peut être reliée à la suite voulue dans le graphe.',
            style: TextStyle(color: colors.textSecondary, fontSize: 11),
          ),
        ],
        const SizedBox(height: 12),
        PokeMapDropdownField<String>(
          key: const ValueKey('scene-interaction-cue'),
          label: 'Moment dans une cinématique de présentation',
          value: _cue,
          items: [
            const PokeMapDropdownItem(
              value: '',
              label: 'Après le bloc précédent',
            ),
            for (final option in widget.cueOptions)
              PokeMapDropdownItem(value: option.value, label: option.label),
          ],
          onChanged: (value) => setState(() => _cue = value),
        ),
        const SizedBox(height: 16),
        Text(
          'Aperçu Player',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          key: const ValueKey('scene-interaction-runtime-preview'),
          height: 250,
          child: interaction == null
              ? PokeMapEmptyState(
                  icon: const Icon(CupertinoIcons.exclamationmark_triangle),
                  title: 'Aperçu indisponible',
                  description:
                      _errorText ?? 'Complétez le texte et les options.',
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Theme(
                    data: PokeMapPlayerTheme.dark(),
                    child: PlayerSceneInteractionSurface(
                      request: interaction.buildRequest(
                        requestId: 'scene-editor-preview',
                        revision: 0,
                      ),
                      allowCancellation: false,
                      onResult: (_) {},
                    ),
                  ),
                ),
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 10),
          PokeMapDiagnosticCallout(
            key: const ValueKey('scene-interaction-validation-error'),
            severity: PokeMapDiagnosticSeverity.error,
            title: 'Interaction incomplète',
            message: _errorText!,
          ),
        ],
        const SizedBox(height: 16),
        PokeMapButton(
          key: const ValueKey('scene-interaction-submit'),
          onPressed: _submit,
          leading: const Icon(CupertinoIcons.check_mark),
          child: const Text('Enregistrer le bloc'),
        ),
      ],
    );
  }

  bool get _supportsOptions =>
      widget.kind == SceneInteractionRequestKind.choice ||
      widget.kind == SceneInteractionRequestKind.selection;

  bool get _supportsConstraints =>
      widget.kind == SceneInteractionRequestKind.text ||
      widget.kind == SceneInteractionRequestKind.selection;

  bool get _usesConfiguredOptions =>
      _binding == ScenePreSessionDraftField.avatarCharacterId.name ||
      _binding == ScenePreSessionDraftField.starterOptionId.name;

  bool get _usesScalarBinding =>
      _binding == ScenePreSessionDraftField.avatarCharacterId.name ||
      _binding == ScenePreSessionDraftField.starterOptionId.name;

  List<PokeMapDropdownItem<String>> get _bindingItems => [
    const PokeMapDropdownItem(value: '', label: 'Ne pas enregistrer'),
    if (widget.kind == SceneInteractionRequestKind.text)
      const PokeMapDropdownItem(value: 'playerName', label: 'Nom du joueur'),
    if (_supportsOptions &&
        widget.newGameConfig.playerAvatarCharacterIds.isNotEmpty)
      const PokeMapDropdownItem(
        value: 'avatarCharacterId',
        label: 'Avatar du joueur',
      ),
    if (_supportsOptions && widget.newGameConfig.starterOptions.isNotEmpty)
      const PokeMapDropdownItem(
        value: 'starterOptionId',
        label: 'Starter choisi',
      ),
  ];

  List<SceneInteractionOption> get _configuredOptions {
    if (_binding == ScenePreSessionDraftField.avatarCharacterId.name) {
      return [
        for (final id in widget.newGameConfig.playerAvatarCharacterIds)
          SceneInteractionOption(
            id: id,
            label: SceneInteractionPrompt(
              localizationKey: 'newGame.avatar.$id',
              fallbackText: _humanize(id),
            ),
          ),
      ];
    }
    if (_binding == ScenePreSessionDraftField.starterOptionId.name) {
      return [
        for (final starter in widget.newGameConfig.starterOptions)
          SceneInteractionOption(
            id: starter.id,
            label: SceneInteractionPrompt(
              localizationKey: 'newGame.starter.${starter.id}',
              fallbackText: starter.label,
            ),
          ),
      ];
    }
    return const <SceneInteractionOption>[];
  }

  ScenePreSessionInteractionSpec? _tryBuildInteraction() {
    try {
      final promptText = _promptController.text.trim();
      if (promptText.isEmpty) return null;
      final prompt = SceneInteractionPrompt(
        localizationKey: _localizationKey(),
        fallbackText: promptText,
      );
      final binding = _binding.isEmpty
          ? null
          : ScenePreSessionResultBinding(
              field: ScenePreSessionDraftField.values.byName(_binding),
            );
      final options = _usesConfiguredOptions
          ? _configuredOptions
          : _narrativeOptions();
      return switch (widget.kind) {
        SceneInteractionRequestKind.message =>
          ScenePreSessionInteractionSpec.message(prompt: prompt),
        SceneInteractionRequestKind.choice =>
          ScenePreSessionInteractionSpec.choice(
            prompt: prompt,
            options: options,
            resultBinding: binding,
          ),
        SceneInteractionRequestKind.text => ScenePreSessionInteractionSpec.text(
          prompt: prompt,
          constraints: SceneTextInputConstraints(
            minGraphemes: _integer(_minimumController.text, fallback: 0),
            maxGraphemes: _integer(_maximumController.text, fallback: 48),
          ),
          resultBinding: binding,
        ),
        SceneInteractionRequestKind.confirmation =>
          ScenePreSessionInteractionSpec.confirmation(prompt: prompt),
        SceneInteractionRequestKind.selection =>
          ScenePreSessionInteractionSpec.selection(
            prompt: prompt,
            options: options,
            constraints: SceneSelectionConstraints(
              minSelections: _integer(_minimumController.text, fallback: 1),
              maxSelections: _usesScalarBinding
                  ? 1
                  : _integer(_maximumController.text, fallback: 1),
            ),
            resultBinding: binding,
          ),
      };
    } on Object {
      return null;
    }
  }

  List<SceneInteractionOption> _narrativeOptions() {
    final labels = _optionsController.text
        .split('\n')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    return [
      for (var index = 0; index < labels.length; index++)
        SceneInteractionOption(
          id: index < (widget.initialInteraction?.options.length ?? 0)
              ? widget.initialInteraction!.options[index].id
              : '${_slug(labels[index])}_${index + 1}',
          label: SceneInteractionPrompt(
            localizationKey: '${_localizationKey()}.option.${index + 1}',
            fallbackText: labels[index],
          ),
        ),
    ];
  }

  String _localizationKey() {
    final authored = _localizationController.text.trim();
    if (authored.isNotEmpty) return authored;
    return 'scene.preSession.${widget.kind.name}.${_slug(_titleController.text)}';
  }

  void _submit() {
    final interaction = _tryBuildInteraction();
    if (interaction == null) {
      setState(() {
        _errorText = _supportsOptions
            ? 'Ajoutez un texte et au moins une option valide.'
            : 'Ajoutez le texte affiché et vérifiez les limites.';
      });
      return;
    }
    final title = _titleController.text.trim();
    final cueBinding = widget.cueOptions
        .where((option) => option.value == _cue)
        .firstOrNull;
    Navigator.of(context).pop(
      ScenePreSessionInteractionDraft(
        title: title.isEmpty
            ? scenePreSessionInteractionKindLabel(widget.kind)
            : title,
        interaction: interaction,
        cueBinding: cueBinding,
      ),
    );
  }
}

int _integer(String raw, {required int fallback}) =>
    int.tryParse(raw.trim()) ?? fallback;

String _slug(String raw) {
  final normalized = raw
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return normalized.isEmpty ? 'interaction' : normalized;
}

String _humanize(String raw) {
  final value = raw.replaceAll(RegExp(r'[_-]+'), ' ').trim();
  if (value.isEmpty) return raw;
  return '${value[0].toUpperCase()}${value.substring(1)}';
}

String _outputPortLabel(String outputPortId) => switch (outputPortId) {
  'completed' => 'Terminé',
  'confirmed' => 'Confirmé',
  'declined' => 'Refusé',
  _ => _humanize(outputPortId),
};

String _formatTime(int microseconds) {
  final totalSeconds = microseconds ~/ Duration.microsecondsPerSecond;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
