import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';

class ProjectMenuLabelsEditor extends StatefulWidget {
  const ProjectMenuLabelsEditor({
    super.key,
    required this.profile,
    required this.onChanged,
  });

  final ProjectMenuLabelsProfile profile;
  final ValueChanged<ProjectMenuLabelsProfile?> onChanged;

  @override
  State<ProjectMenuLabelsEditor> createState() =>
      _ProjectMenuLabelsEditorState();
}

class _ProjectMenuLabelsEditorState extends State<ProjectMenuLabelsEditor> {
  late final Map<_MenuLabelField, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = <_MenuLabelField, TextEditingController>{
      for (final field in _MenuLabelField.values)
        field: TextEditingController(text: field.read(widget.profile) ?? ''),
    };
  }

  @override
  void didUpdateWidget(covariant ProjectMenuLabelsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile == widget.profile) return;
    for (final field in _MenuLabelField.values) {
      final next = field.read(widget.profile) ?? '';
      final controller = _controllers[field]!;
      if (controller.text != next) controller.text = next;
    }
  }

  @override
  void dispose() {
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
                        hintText: 'Par défaut : ${field.fallback}',
                        inputFormatters: <TextInputFormatter>[
                          LengthLimitingTextInputFormatter(
                            projectMenuLabelMaxLength,
                          ),
                        ],
                        onChanged: (_) => _publish(),
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

  void _publish() {
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
      save: value(_MenuLabelField.save),
      options: value(_MenuLabelField.options),
      returnToTitle: value(_MenuLabelField.returnToTitle),
    );
    widget.onChanged(
      profile == const ProjectMenuLabelsProfile() ? null : profile,
    );
  }
}

enum _MenuLabelField {
  pauseTitle('Titre du menu', 'Pause'),
  resume('Reprendre', 'Reprendre'),
  party('Équipe', 'Équipe'),
  bag('Sac', 'Sac'),
  pokedex('Pokédex', 'Pokédex'),
  map('Carte', 'Carte'),
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
    _MenuLabelField.save => profile.save,
    _MenuLabelField.options => profile.options,
    _MenuLabelField.returnToTitle => profile.returnToTitle,
  };
}
