import 'package:flutter/material.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/narrative/application/periodic_reward_selection.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_select.dart';

class PeriodicRewardChoiceScope extends InheritedWidget {
  const PeriodicRewardChoiceScope({
    super.key,
    required this.projectRootPath,
    required super.child,
    this.query,
  });
  final String projectRootPath;
  final Future<AuthoringQueryPage> Function(AuthoringQueryRequest)? query;
  static PeriodicRewardChoiceScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PeriodicRewardChoiceScope>();
  Future<AuthoringQueryPage> read(AuthoringQueryRequest request) =>
      query?.call(request) ??
      Future.error(StateError('Les sources publiées sont indisponibles.'));
  static Widget preserve(BuildContext context, Widget child) {
    final source = of(context);
    return source == null
        ? child
        : PeriodicRewardChoiceScope(
            projectRootPath: source.projectRootPath,
            query: source.query,
            child: child,
          );
  }

  @override
  bool updateShouldNotify(PeriodicRewardChoiceScope oldWidget) =>
      projectRootPath != oldWidget.projectRootPath || query != oldWidget.query;
}

class PeriodicRewardPicker extends StatefulWidget {
  const PeriodicRewardPicker({
    super.key,
    this.initial,
    this.expectedValue = true,
    required this.onApply,
  });
  final PeriodicRewardReference? initial;
  final bool expectedValue;
  final void Function(PeriodicRewardReference, bool) onApply;
  @override
  State<PeriodicRewardPicker> createState() => _PeriodicRewardPickerState();
}

class _PeriodicRewardPickerState extends State<PeriodicRewardPicker> {
  late PeriodicRewardSelection draft;
  PeriodicRewardChoiceScope? _scope;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = PeriodicRewardChoiceScope.of(context);
    if (!_initialized ||
        scope?.projectRootPath != _scope?.projectRootPath ||
        scope?.query != _scope?.query) {
      _scope = scope;
      _reset();
    }
  }

  @override
  void didUpdateWidget(PeriodicRewardPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial != widget.initial ||
        oldWidget.expectedValue != widget.expectedValue) {
      _reset();
    }
  }

  void _reset() {
    if (_initialized) draft.dispose();
    _initialized = true;
    draft = PeriodicRewardSelection(
      initial: widget.initial,
      initialExpectedValue: widget.expectedValue,
      read: _scope?.read,
      changed: () {
        if (mounted) setState(() {});
      },
    );
    draft.loadScenes();
  }

  @override
  void dispose() {
    draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = draft.selected;
    final reference = draft.applicable;
    final unresolved = draft.unresolved;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const StudioNotice(
          'Choisissez une scène enregistrée, puis son action de récompense quotidienne. Les brouillons ne sont pas publiés.',
        ),
        StudioSelect(
          label: 'Scène de la récompense',
          value: draft.scenes.any((scene) => scene.sceneId == draft.sceneId)
              ? draft.sceneId
              : null,
          options: {
            for (final scene in draft.scenes) scene.sceneId: scene.label,
          },
          onChanged: draft.selectScene,
        ),
        if (draft.cursor != null)
          StudioButton(
            label: 'Afficher d’autres scènes',
            secondary: true,
            onPressed: draft.loading
                ? null
                : () => draft.loadScenes(more: true),
          ),
        StudioSelect(
          label: 'Action de récompense',
          value: selected?.nodeId,
          options: {
            for (final node in draft.nodes)
              node.nodeId: '${node.label} × ${node.quantity}',
          },
          onChanged: draft.selectNode,
        ),
        StudioSelect(
          label: 'Disponibilité attendue',
          value: '$draft.expected',
          options: const {
            'true': 'Disponible aujourd’hui',
            'false': 'Déjà récupérée aujourd’hui',
          },
          onChanged: (value) => draft.expected = value == 'true',
        ),
        if (draft.loading)
          const StudioNotice('Chargement des sources publiées…'),
        if (draft.error != null) StudioNotice(draft.error!),
        if (unresolved)
          const StudioNotice(
            'La référence existante reste conservée, mais son action ne peut pas être confirmée. Sélectionnez une action publiée pour la remplacer.',
          ),
        StudioButton(
          label: 'Actualiser les sources',
          secondary: true,
          onPressed: draft.loading ? null : () => draft.loadScenes(),
        ),
        StudioButton(
          label: 'Appliquer la condition quotidienne',
          onPressed: draft.loading || draft.error != null || reference == null
              ? null
              : () => widget.onApply(reference, draft.expected),
        ),
      ],
    );
  }
}
