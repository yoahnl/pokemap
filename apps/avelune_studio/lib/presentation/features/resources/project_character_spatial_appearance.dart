import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/resources/domain/project_character_workshop_port.dart';
import '../../../features/resources/domain/resource_port.dart';
import 'project_character_workshop_preview.dart';

typedef ResolveCharacterSpatialModel = Future<ProjectModel3dEntry?> Function(
  BuildContext context,
  String? modelId,
);

class ProjectCharacterSpatialAppearance extends StatefulWidget {
  const ProjectCharacterSpatialAppearance({
    super.key,
    required this.character,
    required this.models,
    required this.resolveModel,
    required this.enabled,
    required this.edit,
    required this.onDraftChanged,
  });

  final ProjectCharacterEntry character;
  final List<ProjectModel3dEntry> models;
  final ResolveCharacterSpatialModel? resolveModel;
  final bool enabled;
  final EditWorkshopCharacter edit;
  final ValueChanged<bool> onDraftChanged;

  @override
  State<ProjectCharacterSpatialAppearance> createState() =>
      _ProjectCharacterSpatialAppearanceState();
}

class _ProjectCharacterSpatialAppearanceState
    extends State<ProjectCharacterSpatialAppearance> {
  late bool? _contactShadow = widget.character.contactShadow;
  late ProjectCharacterSpatialModel? _binding = widget.character.spatialModel;
  late ProjectModel3dEntry? _model = _knownModel;
  var _state = CharacterAnimationState.idle;
  bool _reading = false;
  String? _problem;

  ProjectModel3dEntry? get _knownModel =>
      widget.models.where((model) => model.id == _binding?.modelId).firstOrNull;
  bool get _shadowChanged => _contactShadow != widget.character.contactShadow;
  bool get _modelChanged => _binding != widget.character.spatialModel;
  bool get _dirty => _shadowChanged || _modelChanged;
  bool get _canSave => !_modelChanged || _binding?.clips.isEmpty != true;
  bool get _enabled => widget.enabled && !_reading;

  @override
  void initState() {
    super.initState();
    _loadBoundModel();
  }

  @override
  void didUpdateWidget(ProjectCharacterSpatialAppearance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_contactShadow == oldWidget.character.contactShadow) {
      _contactShadow = widget.character.contactShadow;
    }
    if (_binding == oldWidget.character.spatialModel) {
      _binding = widget.character.spatialModel;
      if (_model?.id != _binding?.modelId) {
        _model = _knownModel;
        _loadBoundModel();
      }
    }
  }

  void _loadBoundModel() {
    if (_binding case final binding? when _model == null) {
      unawaited(_resolveModel(binding.modelId));
    }
  }

  Future<void> _resolveModel([String? modelId]) async {
    final resolve = widget.resolveModel;
    if (resolve == null || _reading) return;
    setState(() {
      _reading = true;
      _problem = null;
    });
    try {
      final model = await resolve(context, modelId);
      if (!mounted || model == null) return;
      if (modelId != null && _binding?.modelId != model.id) return;
      setState(() {
        _model = model;
        if (_binding?.modelId != model.id) {
          _binding = ProjectCharacterSpatialModel(modelId: model.id);
          _state = CharacterAnimationState.idle;
        }
      });
      widget.onDraftChanged(_dirty);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _problem = error is ResourceFailure
            ? error.message
            : 'Impossible de lire le modèle choisi.';
      });
    } finally {
      if (mounted) setState(() => _reading = false);
    }
  }

  void _detach() {
    setState(() {
      _model = null;
      _binding = null;
      _problem = null;
    });
    widget.onDraftChanged(_dirty);
  }

  void _discard() {
    setState(() {
      _contactShadow = widget.character.contactShadow;
      _binding = widget.character.spatialModel;
      if (_model?.id != _binding?.modelId) _model = _knownModel;
      _state = CharacterAnimationState.idle;
      _problem = null;
    });
    _loadBoundModel();
    widget.onDraftChanged(false);
  }

  void _selectClip(String value) {
    final binding = _binding!;
    final clips = Map.of(binding.clips);
    if (value == 'none') {
      clips.remove(_state);
    } else {
      clips[_state] = int.parse(value);
    }
    setState(() => _binding = binding.copyWith(clips: clips));
    widget.onDraftChanged(_dirty);
  }

  void _selectShadow(String value) {
    setState(() {
      _contactShadow = switch (value) {
        'enabled' => true,
        'disabled' => false,
        _ => null,
      };
    });
    widget.onDraftChanged(_dirty);
  }

  Future<void> _save() async {
    final saved = await widget.edit('characterStudio.character.update', {
      if (_shadowChanged) 'contactShadow': _contactShadow,
      if (_modelChanged) 'spatialModel': _binding?.toJson(),
    });
    if (mounted && saved) widget.onDraftChanged(false);
  }

  Widget _modelPanel(BuildContext context) {
    final model = _model;
    final binding = _binding;
    return StudioPanel(
      title: 'Modèle du personnage',
      icon: Icons.view_in_ar_outlined,
      children: [
        Text(
          model?.name ?? (binding == null ? 'Sprite 2D' : 'Modèle associé'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (widget.resolveModel != null || binding != null) ...[
          const SizedBox(height: StudioSpacing.m),
          Wrap(
            spacing: StudioSpacing.s,
            runSpacing: StudioSpacing.s,
            children: [
              if (widget.resolveModel != null)
                StudioButton(
                  label: binding == null
                      ? 'Choisir un modèle'
                      : 'Changer de modèle',
                  icon: Icons.folder_open_outlined,
                  variant: StudioButtonVariant.secondary,
                  onPressed: _enabled ? _resolveModel : null,
                ),
              if (binding != null)
                StudioButton(
                  label: 'Utiliser le sprite',
                  variant: StudioButtonVariant.quiet,
                  onPressed: _enabled ? _detach : null,
                ),
            ],
          ),
        ],
        if (_reading) const LinearProgressIndicator(minHeight: 2),
        if (_problem case final problem?) StudioNotice(problem, isError: true),
        if (model != null && binding != null) ...[
          const SizedBox(height: StudioSpacing.l),
          StudioSelect(
            label: 'État du personnage',
            value: _state.name,
            options: {
              for (final state in CharacterAnimationState.values)
                state.name: characterAnimationLabel(state),
            },
            onChanged: _enabled
                ? (value) => setState(
                    () => _state = CharacterAnimationState.values.byName(value),
                  )
                : null,
          ),
          const SizedBox(height: StudioSpacing.m),
          StudioSelect(
            label: 'Clip GLB',
            value: binding.clips[_state]?.toString() ?? 'none',
            options: {
              'none': 'Aucun clip pour cet état',
              for (final clip in model.inspection.animations)
                '${clip.index}': clip.name,
            },
            onChanged: _enabled ? _selectClip : null,
          ),
          if (binding.clips.isNotEmpty) ...[
            const SizedBox(height: StudioSpacing.m),
            const Text(
              'Un état sans clip utilise le clip Au repos s’il existe. '
              'Sinon, le personnage garde son sprite.',
            ),
          ],
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.all(StudioSpacing.xl),
          children: [
            _modelPanel(context),
            const SizedBox(height: StudioSpacing.l),
            StudioPanel(
              title: 'Ombre sur les cartes 3D',
              icon: Icons.layers_outlined,
              children: [
                StudioSelect(
                  label: 'Ombre de contact',
                  value: switch (_contactShadow) {
                    true => 'enabled',
                    false => 'disabled',
                    null => 'project',
                  },
                  options: const {
                    'project': 'Réglage du projet',
                    'enabled': 'Toujours afficher',
                    'disabled': 'Masquer',
                  },
                  onChanged: _enabled ? _selectShadow : null,
                ),
              ],
            ),
          ],
        ),
      ),
      const Divider(height: 1),
      StudioActionBar(
        message: _canSave ? null : 'Associez au moins un clip à ce modèle.',
        actions: [
          if (_dirty)
            StudioButton(
              label: 'Annuler les modifications',
              variant: StudioButtonVariant.quiet,
              onPressed: _enabled ? _discard : null,
            ),
          StudioButton(
            label: 'Enregistrer l’apparence',
            icon: Icons.save_outlined,
            onPressed: _enabled && _dirty && _canSave ? _save : null,
          ),
        ],
      ),
    ],
  );
}
