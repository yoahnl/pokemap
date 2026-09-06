import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';
import 'personalization_deferred_commit.dart';
import 'project_pause_composition_editor.dart';

class ProjectPauseActionsEditor extends StatefulWidget {
  const ProjectPauseActionsEditor({
    super.key,
    required this.profile,
    required this.onChanged,
    this.onPreviewChanged,
    this.commitCoordinator,
  });

  final ProjectPausePresentationProfile profile;
  final ValueChanged<ProjectPausePresentationProfile?> onChanged;
  final ValueChanged<ProjectPausePresentationProfile?>? onPreviewChanged;
  final PersonalizationDeferredCommitCoordinator? commitCoordinator;

  @override
  State<ProjectPauseActionsEditor> createState() =>
      _ProjectPauseActionsEditorState();
}

class _ProjectPauseActionsEditorState extends State<ProjectPauseActionsEditor> {
  late List<ProjectPauseActionProfile> _actions;
  late final TextEditingController _title;
  late final TextEditingController _hint;
  late final Map<ProjectPauseActionId, TextEditingController> _labels;
  late final FocusNode _titleFocusNode;
  late final FocusNode _hintFocusNode;
  late final Map<ProjectPauseActionId, FocusNode> _labelFocusNodes;
  late final PersonalizationDeferredCommit _commit;

  @override
  void initState() {
    super.initState();
    _commit = PersonalizationDeferredCommit(widget.commitCoordinator);
    _actions = _effectiveActions(widget.profile.actions);
    _title = TextEditingController(text: widget.profile.title ?? '');
    _hint = TextEditingController(text: widget.profile.hint ?? '');
    _labels = <ProjectPauseActionId, TextEditingController>{
      for (final action in _actions)
        action.id: TextEditingController(text: action.label ?? ''),
    };
    _titleFocusNode = _newFocusNode();
    _hintFocusNode = _newFocusNode();
    _labelFocusNodes = <ProjectPauseActionId, FocusNode>{
      for (final action in _actions) action.id: _newFocusNode(),
    };
  }

  @override
  void didUpdateWidget(covariant ProjectPauseActionsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_commit.hasPending) return;
    if (oldWidget.profile == widget.profile) return;
    _syncController(_title, widget.profile.title);
    _syncController(_hint, widget.profile.hint);
    _actions = _effectiveActions(widget.profile.actions);
    for (final action in _actions) {
      final controller = _labels.putIfAbsent(
        action.id,
        () => TextEditingController(),
      );
      _labelFocusNodes.putIfAbsent(action.id, _newFocusNode);
      _syncController(controller, action.label);
    }
  }

  @override
  void dispose() {
    _commit.flush();
    _commit.dispose();
    _titleFocusNode
      ..removeListener(_flushWhenFocusLeaves)
      ..dispose();
    _hintFocusNode
      ..removeListener(_flushWhenFocusLeaves)
      ..dispose();
    for (final node in _labelFocusNodes.values) {
      node
        ..removeListener(_flushWhenFocusLeaves)
        ..dispose();
    }
    _title.dispose();
    _hint.dispose();
    for (final controller in _labels.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      const PokeMapSectionHeader(
        title: 'Contenu et actions',
        description:
            'Renommez, réordonnez et choisissez les entrées visibles du vrai menu Pause.',
      ),
      const SizedBox(height: 8),
      PokeMapCard(
        child: Column(
          children: <Widget>[
            PokeMapTextField(
              label: 'Titre',
              fieldKey: const ValueKey<String>('pause-presentation-title'),
              controller: _title,
              focusNode: _titleFocusNode,
              hintText: 'Par défaut : Pause',
              inputFormatters: <TextInputFormatter>[
                LengthLimitingTextInputFormatter(projectPauseTitleMaxLength),
              ],
              onChanged: (_) => _publish(deferred: true),
              onSubmitted: (_) => _commit.flush(),
            ),
            const SizedBox(height: 10),
            PokeMapTextField(
              label: 'Aide de commande',
              fieldKey: const ValueKey<String>('pause-presentation-hint'),
              controller: _hint,
              focusNode: _hintFocusNode,
              hintText: 'Par défaut : Entrée / bouton A. Pause',
              inputFormatters: <TextInputFormatter>[
                LengthLimitingTextInputFormatter(projectPauseHintMaxLength),
              ],
              onChanged: (_) => _publish(deferred: true),
              onSubmitted: (_) => _commit.flush(),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerLeft,
        child: PokeMapButton(
          key: const ValueKey<String>('pause-actions-reset'),
          size: PokeMapButtonSize.small,
          variant: PokeMapButtonVariant.ghost,
          leading: const Icon(Icons.restart_alt_rounded),
          onPressed: _reset,
          child: const Text('Réglages du jeu'),
        ),
      ),
      const SizedBox(height: 8),
      for (final (index, action) in _actions.indexed) ...<Widget>[
        KeyedSubtree(
          key: ValueKey<String>('pause-action-${action.id.name}'),
          child: PokeMapCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _label(action.id),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    PokeMapIconButton(
                      key: ValueKey<String>(
                        'pause-action-up-${action.id.name}',
                      ),
                      tooltip: 'Monter',
                      semanticLabel: 'Monter ${_label(action.id)}',
                      onPressed: index == 0 ? null : () => _move(index, -1),
                      icon: const Icon(Icons.arrow_upward_rounded),
                    ),
                    const SizedBox(width: 4),
                    PokeMapIconButton(
                      key: ValueKey<String>(
                        'pause-action-down-${action.id.name}',
                      ),
                      tooltip: 'Descendre',
                      semanticLabel: 'Descendre ${_label(action.id)}',
                      onPressed: index == _actions.length - 1
                          ? null
                          : () => _move(index, 1),
                      icon: const Icon(Icons.arrow_downward_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 430;
                    final fields = <Widget>[
                      PokeMapTextField(
                        label: 'Libellé',
                        fieldKey: ValueKey<String>(
                          'pause-action-label-${action.id.name}',
                        ),
                        controller: _labels[action.id],
                        focusNode: _labelFocusNodes[action.id],
                        hintText: 'Par défaut : ${_label(action.id)}',
                        inputFormatters: <TextInputFormatter>[
                          LengthLimitingTextInputFormatter(
                            projectPauseActionLabelMaxLength,
                          ),
                        ],
                        onChanged: (value) => _replace(
                          index,
                          action.copyWith(
                            label: value.trim().isEmpty ? null : value,
                          ),
                          deferred: true,
                        ),
                        onSubmitted: (_) => _commit.flush(),
                      ),
                      PokeMapDropdownField<ProjectPauseActionIcon>(
                        key: ValueKey<String>(
                          'pause-action-icon-${action.id.name}',
                        ),
                        label: 'Icône',
                        value: action.icon ?? _defaultIcon(action.id),
                        items: _iconItems,
                        onChanged: (icon) =>
                            _replace(index, action.copyWith(icon: icon)),
                      ),
                    ];
                    if (stacked) {
                      return Column(
                        children: <Widget>[
                          fields.first,
                          const SizedBox(height: 10),
                          fields.last,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(child: fields.first),
                        const SizedBox(width: 12),
                        Expanded(child: fields.last),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                if (action.id == ProjectPauseActionId.resume)
                  const PokeMapBadge(
                    label: 'Toujours visible',
                    variant: PokeMapBadgeVariant.info,
                  )
                else
                  PokeMapToggleTile(
                    key: ValueKey<String>(
                      'pause-action-visible-${action.id.name}',
                    ),
                    label: 'Afficher cette entrée',
                    value: action.visible,
                    onChanged: (visible) =>
                        _replace(index, action.copyWith(visible: visible)),
                  ),
              ],
            ),
          ),
        ),
        if (index < _actions.length - 1) const SizedBox(height: 8),
      ],
      const SizedBox(height: 18),
      ProjectPauseCompositionEditor(
        profile:
            widget.profile.composition ??
            const ProjectResponsivePauseCompositionProfile(),
        onChanged: (composition) =>
            _commitImmediately(_currentProfile(composition)),
      ),
    ],
  );

  void _move(int index, int offset) {
    setState(() {
      final action = _actions.removeAt(index);
      _actions.insert(index + offset, action);
    });
    _publish();
  }

  FocusNode _newFocusNode() {
    final node = FocusNode();
    node.addListener(_flushWhenFocusLeaves);
    return node;
  }

  void _flushWhenFocusLeaves() {
    if (!_titleFocusNode.hasFocus &&
        !_hintFocusNode.hasFocus &&
        _labelFocusNodes.values.every((node) => !node.hasFocus)) {
      _commit.flush();
    }
  }

  void _replace(
    int index,
    ProjectPauseActionProfile action, {
    bool deferred = false,
  }) {
    setState(() => _actions[index] = action);
    _publish(deferred: deferred);
  }

  void _reset() {
    _commit.cancel();
    setState(() {
      _title.clear();
      _hint.clear();
      _actions = List<ProjectPauseActionProfile>.of(defaultProjectPauseActions);
      for (final action in _actions) {
        _labels[action.id]?.clear();
      }
    });
    widget.onChanged(null);
  }

  void _publish({bool deferred = false}) {
    final profile = _currentProfile(widget.profile.composition);
    if (deferred) {
      widget.onPreviewChanged?.call(profile);
      final onChanged = widget.onChanged;
      _commit.schedule(() => onChanged(profile));
      return;
    }
    _commitImmediately(profile);
  }

  void _commitImmediately(ProjectPausePresentationProfile profile) {
    _commit.cancel();
    widget.onChanged(profile);
  }

  ProjectPausePresentationProfile _currentProfile(
    ProjectResponsivePauseCompositionProfile? composition,
  ) => widget.profile.copyWith(
    title: _optional(_title.text),
    hint: _optional(_hint.text),
    actions: List<ProjectPauseActionProfile>.of(_actions),
    composition: composition,
  );
}

List<ProjectPauseActionProfile> _effectiveActions(
  List<ProjectPauseActionProfile>? authored,
) {
  if (authored == null) {
    return List<ProjectPauseActionProfile>.of(defaultProjectPauseActions);
  }
  final ids = authored.map((action) => action.id).toSet();
  return <ProjectPauseActionProfile>[
    ...authored,
    for (final action in defaultProjectPauseActions)
      if (!ids.contains(action.id))
        action.copyWith(visible: action.id == ProjectPauseActionId.resume),
  ];
}

void _syncController(TextEditingController controller, String? value) {
  final next = value ?? '';
  if (controller.text != next) controller.text = next;
}

String? _optional(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _label(ProjectPauseActionId id) => switch (id) {
  ProjectPauseActionId.resume => 'Reprendre',
  ProjectPauseActionId.party => 'Équipe',
  ProjectPauseActionId.bag => 'Sac',
  ProjectPauseActionId.pokedex => 'Pokédex',
  ProjectPauseActionId.map => 'Carte',
  ProjectPauseActionId.quests => 'Quêtes',
  ProjectPauseActionId.profile => 'Profil',
  ProjectPauseActionId.save => 'Sauvegarder',
  ProjectPauseActionId.options => 'Options',
  ProjectPauseActionId.returnToTitle => 'Retour au titre',
};

ProjectPauseActionIcon _defaultIcon(ProjectPauseActionId id) =>
    defaultProjectPauseActions.singleWhere((action) => action.id == id).icon!;

const _iconItems = <PokeMapDropdownItem<ProjectPauseActionIcon>>[
  PokeMapDropdownItem(value: ProjectPauseActionIcon.play, label: 'Lecture'),
  PokeMapDropdownItem(value: ProjectPauseActionIcon.party, label: 'Équipe'),
  PokeMapDropdownItem(value: ProjectPauseActionIcon.bag, label: 'Sac'),
  PokeMapDropdownItem(value: ProjectPauseActionIcon.book, label: 'Livre'),
  PokeMapDropdownItem(value: ProjectPauseActionIcon.person, label: 'Profil'),
  PokeMapDropdownItem(value: ProjectPauseActionIcon.map, label: 'Carte'),
  PokeMapDropdownItem(value: ProjectPauseActionIcon.save, label: 'Sauvegarde'),
  PokeMapDropdownItem(
    value: ProjectPauseActionIcon.settings,
    label: 'Réglages',
  ),
  PokeMapDropdownItem(value: ProjectPauseActionIcon.exit, label: 'Sortie'),
];
