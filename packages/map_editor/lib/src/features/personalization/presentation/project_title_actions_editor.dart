import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';
import 'personalization_deferred_commit.dart';

class ProjectTitleActionsEditor extends StatefulWidget {
  const ProjectTitleActionsEditor({
    super.key,
    required this.profile,
    required this.onChanged,
    this.onPreviewChanged,
    this.commitCoordinator,
  });

  final ProjectTitlePresentationProfile profile;
  final ValueChanged<ProjectTitlePresentationProfile> onChanged;
  final ValueChanged<ProjectTitlePresentationProfile>? onPreviewChanged;
  final PersonalizationDeferredCommitCoordinator? commitCoordinator;

  @override
  State<ProjectTitleActionsEditor> createState() =>
      _ProjectTitleActionsEditorState();
}

class _ProjectTitleActionsEditorState extends State<ProjectTitleActionsEditor> {
  late List<ProjectTitleActionProfile> _actions;
  late final Map<ProjectTitleActionId, TextEditingController> _labels;
  late final Map<ProjectTitleActionId, FocusNode> _focusNodes;
  late final PersonalizationDeferredCommit _commit;

  @override
  void initState() {
    super.initState();
    _commit = PersonalizationDeferredCommit(widget.commitCoordinator);
    _actions = _effectiveActions(widget.profile.actions);
    _labels = <ProjectTitleActionId, TextEditingController>{
      for (final action in _actions)
        action.id: TextEditingController(text: action.label ?? ''),
    };
    _focusNodes = <ProjectTitleActionId, FocusNode>{
      for (final action in _actions) action.id: _newFocusNode(),
    };
  }

  @override
  void didUpdateWidget(covariant ProjectTitleActionsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_commit.hasPending) return;
    if (oldWidget.profile == widget.profile) return;
    _actions = _effectiveActions(widget.profile.actions);
    for (final action in _actions) {
      final controller = _labels.putIfAbsent(
        action.id,
        () => TextEditingController(),
      );
      _focusNodes.putIfAbsent(action.id, _newFocusNode);
      final next = action.label ?? '';
      if (controller.text != next) controller.text = next;
    }
  }

  @override
  void dispose() {
    _commit.flush();
    _commit.dispose();
    for (final node in _focusNodes.values) {
      node
        ..removeListener(_flushWhenFocusLeaves)
        ..dispose();
    }
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
        title: 'Boutons du menu',
        description:
            'Réordonnez, renommez et choisissez les boutons visibles. '
            'Leur disponibilité reste décidée par la sauvegarde et le jeu.',
      ),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerLeft,
        child: PokeMapButton(
          key: const ValueKey<String>('title-actions-reset'),
          size: PokeMapButtonSize.small,
          variant: PokeMapButtonVariant.ghost,
          leading: const Icon(Icons.restart_alt_rounded),
          onPressed: _reset,
          child: const Text('Réglages du lecteur'),
        ),
      ),
      const SizedBox(height: 8),
      for (final (index, action) in _actions.indexed) ...<Widget>[
        KeyedSubtree(
          key: ValueKey<String>('title-action-${action.id.name}'),
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
                        'title-action-up-${action.id.name}',
                      ),
                      tooltip: 'Monter',
                      semanticLabel: 'Monter ${_label(action.id)}',
                      onPressed: index == 0 ? null : () => _move(index, -1),
                      icon: const Icon(Icons.arrow_upward_rounded),
                    ),
                    const SizedBox(width: 4),
                    PokeMapIconButton(
                      key: ValueKey<String>(
                        'title-action-down-${action.id.name}',
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
                          'title-action-label-${action.id.name}',
                        ),
                        controller: _labels[action.id],
                        focusNode: _focusNodes[action.id],
                        hintText: 'Par défaut : ${_label(action.id)}',
                        inputFormatters: <TextInputFormatter>[
                          LengthLimitingTextInputFormatter(
                            projectTitleActionLabelMaxLength,
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
                      PokeMapDropdownField<ProjectTitleActionIcon>(
                        key: ValueKey<String>(
                          'title-action-icon-${action.id.name}',
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
                if (action.id == ProjectTitleActionId.newGame)
                  const PokeMapBadge(
                    label: 'Toujours visible',
                    variant: PokeMapBadgeVariant.info,
                  )
                else
                  PokeMapToggleTile(
                    key: ValueKey<String>(
                      'title-action-visible-${action.id.name}',
                    ),
                    label: 'Afficher ce bouton',
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
    if (_focusNodes.values.every((node) => !node.hasFocus)) {
      _commit.flush();
    }
  }

  void _replace(
    int index,
    ProjectTitleActionProfile action, {
    bool deferred = false,
  }) {
    setState(() => _actions[index] = action);
    _publish(deferred: deferred);
  }

  void _reset() {
    _commit.cancel();
    setState(() {
      _actions = _effectiveActions(null);
      for (final action in _actions) {
        _labels[action.id]?.text = '';
      }
    });
    widget.onChanged(widget.profile.copyWith(actions: null));
  }

  void _publish({bool deferred = false}) {
    final profile = widget.profile.copyWith(actions: List.of(_actions));
    if (deferred) {
      widget.onPreviewChanged?.call(profile);
      final onChanged = widget.onChanged;
      _commit.schedule(() => onChanged(profile));
      return;
    }
    _commit.cancel();
    widget.onChanged(profile);
  }
}

List<ProjectTitleActionProfile> _effectiveActions(
  List<ProjectTitleActionProfile>? authored,
) {
  if (authored == null) return List.of(defaultProjectTitleActions);
  final ids = authored.map((action) => action.id).toSet();
  return <ProjectTitleActionProfile>[
    for (final action in authored)
      action.id == ProjectTitleActionId.newGame
          ? action.copyWith(visible: true)
          : action,
    for (final action in defaultProjectTitleActions)
      if (!ids.contains(action.id))
        action.copyWith(visible: action.id == ProjectTitleActionId.newGame),
  ];
}

String _label(ProjectTitleActionId id) => switch (id) {
  ProjectTitleActionId.continueGame => 'Continuer',
  ProjectTitleActionId.newGame => 'Nouveau jeu',
  ProjectTitleActionId.load => 'Charger',
  ProjectTitleActionId.options => 'Options',
  ProjectTitleActionId.creditsAbout => 'Crédits / À propos',
  ProjectTitleActionId.returnToHub => 'Retour au Hub',
};

ProjectTitleActionIcon _defaultIcon(ProjectTitleActionId id) =>
    defaultProjectTitleActions.singleWhere((action) => action.id == id).icon!;

const _iconItems = <PokeMapDropdownItem<ProjectTitleActionIcon>>[
  PokeMapDropdownItem(value: ProjectTitleActionIcon.play, label: 'Lecture'),
  PokeMapDropdownItem(
    value: ProjectTitleActionIcon.sparkles,
    label: 'Étincelles',
  ),
  PokeMapDropdownItem(value: ProjectTitleActionIcon.folder, label: 'Dossier'),
  PokeMapDropdownItem(
    value: ProjectTitleActionIcon.settings,
    label: 'Réglages',
  ),
  PokeMapDropdownItem(value: ProjectTitleActionIcon.info, label: 'Information'),
  PokeMapDropdownItem(value: ProjectTitleActionIcon.home, label: 'Accueil'),
];
