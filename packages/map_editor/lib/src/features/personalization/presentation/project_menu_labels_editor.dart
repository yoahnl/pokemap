import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';
import 'personalization_deferred_commit.dart';

class ProjectMenuLabelsEditor extends StatefulWidget {
  const ProjectMenuLabelsEditor({
    super.key,
    required this.profile,
    required this.onChanged,
    this.onPreviewChanged,
    this.commitCoordinator,
  });

  final ProjectMenuLabelsProfile profile;
  final ValueChanged<ProjectMenuLabelsProfile?> onChanged;
  final ValueChanged<ProjectMenuLabelsProfile?>? onPreviewChanged;
  final PersonalizationDeferredCommitCoordinator? commitCoordinator;

  @override
  State<ProjectMenuLabelsEditor> createState() =>
      _ProjectMenuLabelsEditorState();
}

class _ProjectMenuLabelsEditorState extends State<ProjectMenuLabelsEditor> {
  late final Map<_MenuLabelField, TextEditingController> _controllers;
  late final Map<_MenuLabelField, FocusNode> _focusNodes;
  late final PersonalizationDeferredCommit _commit;

  @override
  void initState() {
    super.initState();
    _commit = PersonalizationDeferredCommit(widget.commitCoordinator);
    _controllers = <_MenuLabelField, TextEditingController>{
      for (final field in _MenuLabelField.values)
        field: TextEditingController(text: field.read(widget.profile) ?? ''),
    };
    _focusNodes = <_MenuLabelField, FocusNode>{
      for (final field in _MenuLabelField.values) field: FocusNode(),
    };
    for (final node in _focusNodes.values) {
      node.addListener(_flushWhenFocusLeaves);
    }
  }

  @override
  void didUpdateWidget(covariant ProjectMenuLabelsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_commit.hasPending) return;
    if (oldWidget.profile == widget.profile) return;
    for (final field in _MenuLabelField.values) {
      final next = field.read(widget.profile) ?? '';
      final controller = _controllers[field]!;
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
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const PokeMapSectionHeader(
          title: 'Libellés du menu Pause',
          description:
              'Laissez un champ vide pour utiliser automatiquement la traduction du joueur.',
        ),
        const SizedBox(height: 8),
        PokeMapCard(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 620 ? 2 : 1;
              final width = columns == 2
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  for (final field in _MenuLabelField.values)
                    SizedBox(
                      width: width,
                      child: PokeMapTextField(
                        label: field.label,
                        fieldKey: ValueKey<String>('menu-label-${field.name}'),
                        controller: _controllers[field],
                        focusNode: _focusNodes[field],
                        hintText: 'Par défaut : ${field.fallback}',
                        inputFormatters: <TextInputFormatter>[
                          LengthLimitingTextInputFormatter(
                            projectMenuLabelMaxLength,
                          ),
                        ],
                        onChanged: (_) => _previewAndSchedule(),
                        onSubmitted: (_) => _commit.flush(),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _flushWhenFocusLeaves() {
    if (_focusNodes.values.every((node) => !node.hasFocus)) {
      _commit.flush();
    }
  }

  void _previewAndSchedule() {
    final profile = _currentProfile();
    widget.onPreviewChanged?.call(profile);
    final onChanged = widget.onChanged;
    _commit.schedule(() => onChanged(profile));
  }

  ProjectMenuLabelsProfile? _currentProfile() {
    String? value(_MenuLabelField field) {
      final text = _controllers[field]!.text.trim();
      return text.isEmpty ? null : text;
    }

    final profile = ProjectMenuLabelsProfile(
      pauseTitle: value(_MenuLabelField.pauseTitle),
      resume: value(_MenuLabelField.resume),
      party: value(_MenuLabelField.party),
      bag: value(_MenuLabelField.bag),
      pokedex: value(_MenuLabelField.pokedex),
      map: value(_MenuLabelField.map),
      quests: value(_MenuLabelField.quests),
      profile: value(_MenuLabelField.profile),
      save: value(_MenuLabelField.save),
      options: value(_MenuLabelField.options),
      returnToTitle: value(_MenuLabelField.returnToTitle),
    );
    return profile == const ProjectMenuLabelsProfile() ? null : profile;
  }
}

enum _MenuLabelField {
  pauseTitle('Titre du menu', 'Pause'),
  resume('Reprendre', 'Reprendre'),
  party('Équipe', 'Équipe'),
  bag('Sac', 'Sac'),
  pokedex('Pokédex', 'Pokédex'),
  map('Carte', 'Carte'),
  quests('Quêtes', 'Quêtes'),
  profile('Profil', 'Profil'),
  save('Sauvegarder', 'Sauvegarder'),
  options('Options', 'Options'),
  returnToTitle('Retour au titre', 'Retour au titre');

  const _MenuLabelField(this.label, this.fallback);

  final String label;
  final String fallback;

  String? read(ProjectMenuLabelsProfile profile) => switch (this) {
    _MenuLabelField.pauseTitle => profile.pauseTitle,
    _MenuLabelField.resume => profile.resume,
    _MenuLabelField.party => profile.party,
    _MenuLabelField.bag => profile.bag,
    _MenuLabelField.pokedex => profile.pokedex,
    _MenuLabelField.map => profile.map,
    _MenuLabelField.quests => profile.quests,
    _MenuLabelField.profile => profile.profile,
    _MenuLabelField.save => profile.save,
    _MenuLabelField.options => profile.options,
    _MenuLabelField.returnToTitle => profile.returnToTitle,
  };
}
