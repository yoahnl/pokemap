import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../../application/use_cases/character_use_cases.dart';
import '../../../../theme/theme.dart';
import '../../../../ui/design_system/design_system.dart';

typedef PortraitStateCreateCallback = Future<void> Function(String label);
typedef PortraitStateRenameCallback =
    Future<void> Function(String id, String label);
typedef PortraitStatesReorderCallback =
    Future<void> Function(List<String> orderedIds);
typedef PortraitStateDeletePreviewCallback =
    Future<PortraitStateDeletePlan?> Function(String id);
typedef PortraitStateDeleteCallback =
    Future<void> Function(
      String id,
      PortraitStateDeleteResolution resolution,
      String? replacementId,
    );

class PortraitStateManager extends StatefulWidget {
  const PortraitStateManager({
    super.key,
    required this.project,
    required this.isSaving,
    required this.onCreate,
    required this.onRename,
    required this.onReorder,
    required this.onPreviewDelete,
    required this.onDelete,
  });

  final ProjectManifest project;
  final bool isSaving;
  final PortraitStateCreateCallback onCreate;
  final PortraitStateRenameCallback onRename;
  final PortraitStatesReorderCallback onReorder;
  final PortraitStateDeletePreviewCallback onPreviewDelete;
  final PortraitStateDeleteCallback onDelete;

  @override
  State<PortraitStateManager> createState() => _PortraitStateManagerState();
}

class _PortraitStateManagerState extends State<PortraitStateManager> {
  bool _isBusy = false;
  String? _feedback;

  bool get _locked => widget.isSaving || _isBusy;

  List<CharacterPortraitStateDefinition> get _states {
    return widget.project.characterStudioCatalog.portraitStates.toList()
      ..sort((left, right) {
        final order = left.sortOrder.compareTo(right.sortOrder);
        return order != 0 ? order : left.id.compareTo(right.id);
      });
  }

  @override
  Widget build(BuildContext context) {
    final states = _states;
    return ListView(
      key: const ValueKey<String>('portrait-state-manager'),
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PokeMapIconTile(
              icon: CupertinoIcons.person_2_square_stack_fill,
              tone: PokeMapTone.cinematic,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expressions globales',
                    style: TextStyle(
                      color: context.pokeMapColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Une liste commune à tous les personnages et dialogues du projet.',
                    style: TextStyle(
                      color: context.pokeMapColors.textSecondary,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            PokeMapButton(
              key: const ValueKey<String>('portrait-state-create'),
              onPressed: _locked ? null : _create,
              size: PokeMapButtonSize.small,
              leading: const Icon(CupertinoIcons.add),
              child: const Text('Nouvelle expression'),
            ),
          ],
        ),
        if (_feedback case final feedback?) ...[
          const SizedBox(height: 14),
          PokeMapActionBanner(
            title: 'Catalogue mis à jour',
            message: feedback,
            tone: PokeMapTone.success,
            dismissLabel: 'Masquer',
            onDismiss: () => setState(() => _feedback = null),
          ),
        ],
        const SizedBox(height: 16),
        if (states.isEmpty)
          const PokeMapEmptyState(
            title: 'Aucune expression globale',
            description:
                'Créez votre premier état pour commencer à attribuer des portraits.',
            icon: Icon(CupertinoIcons.smiley),
          )
        else
          for (var index = 0; index < states.length; index++) ...[
            _PortraitStateCard(
              definition: states[index],
              coverage: _coverage(states[index].id),
              characterCount: widget.project.characters.length,
              isLocked: _locked,
              canMoveUp: index > 0,
              canMoveDown: index < states.length - 1,
              onMoveUp: () => _move(index, -1),
              onMoveDown: () => _move(index, 1),
              onRename: () => _rename(states[index]),
              onDelete: () => _delete(states[index]),
            ),
            if (index != states.length - 1) const SizedBox(height: 8),
          ],
      ],
    );
  }

  int _coverage(String stateId) {
    return widget.project.characters
        .where(
          (character) => character.portraits.any(
            (portrait) => portrait.portraitStateId == stateId,
          ),
        )
        .length;
  }

  Future<void> _create() async {
    final controller = TextEditingController();
    final confirmed = await showPokeMapPromptDialog(
      context,
      title: 'Nouvelle expression globale',
      controller: controller,
      placeholder: 'Nom affiché',
      cancelLabel: 'Annuler',
      confirmLabel: 'Créer',
    );
    final label = controller.text.trim();
    controller.dispose();
    if (!confirmed || label.isEmpty || !mounted) return;
    await _run(
      () => widget.onCreate(label),
      'L’expression « $label » a été créée.',
    );
  }

  Future<void> _rename(CharacterPortraitStateDefinition definition) async {
    final controller = TextEditingController(text: definition.displayName);
    final confirmed = await showPokeMapPromptDialog(
      context,
      title: 'Renommer ${definition.displayName}',
      controller: controller,
      placeholder: 'Nom affiché',
      cancelLabel: 'Annuler',
      confirmLabel: 'Enregistrer',
    );
    final label = controller.text.trim();
    controller.dispose();
    if (!confirmed || label.isEmpty || !mounted) return;
    await _run(
      () => widget.onRename(definition.id, label),
      'Le libellé a été remplacé par « $label ». La clé ${definition.id} reste inchangée.',
    );
  }

  Future<void> _move(int index, int offset) async {
    final ids = _states.map((state) => state.id).toList();
    final target = index + offset;
    if (target < 0 || target >= ids.length) return;
    final moved = ids.removeAt(index);
    ids.insert(target, moved);
    await _run(
      () => widget.onReorder(ids),
      'L’ordre des expressions a été mis à jour.',
    );
  }

  Future<void> _delete(CharacterPortraitStateDefinition definition) async {
    setState(() => _isBusy = true);
    final plan = await widget.onPreviewDelete(definition.id);
    if (!mounted) return;
    setState(() => _isBusy = false);
    if (plan == null) return;
    final decision = await showPortraitStateDeleteDialog(
      context: context,
      project: widget.project,
      stateLabel: definition.displayName,
      plan: plan,
    );
    if (decision == null || !mounted) return;
    await _run(
      () => widget.onDelete(
        definition.id,
        decision.resolution,
        decision.replacementId,
      ),
      'L’expression « ${definition.displayName} » a été supprimée.',
    );
  }

  Future<void> _run(Future<void> Function() operation, String feedback) async {
    setState(() {
      _isBusy = true;
      _feedback = null;
    });
    try {
      await operation();
      if (mounted) setState(() => _feedback = feedback);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }
}

class _PortraitStateCard extends StatelessWidget {
  const _PortraitStateCard({
    required this.definition,
    required this.coverage,
    required this.characterCount,
    required this.isLocked,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRename,
    required this.onDelete,
  });

  final CharacterPortraitStateDefinition definition;
  final int coverage;
  final int characterCount;
  final bool isLocked;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final complete = characterCount > 0 && coverage == characterCount;
    return PokeMapCard(
      key: ValueKey<String>('portrait-state-card-${definition.id}'),
      child: Row(
        children: [
          PokeMapIconTile(
            icon: complete ? CupertinoIcons.smiley_fill : CupertinoIcons.smiley,
            tone: complete ? PokeMapTone.success : PokeMapTone.warning,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  definition.displayName,
                  style: TextStyle(
                    color: context.pokeMapColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  definition.id,
                  style: TextStyle(
                    color: context.pokeMapColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          PokeMapBadge(
            label: '$coverage/$characterCount personnages',
            variant: complete
                ? PokeMapBadgeVariant.success
                : PokeMapBadgeVariant.warning,
          ),
          const SizedBox(width: 8),
          PokeMapIconButton(
            key: ValueKey<String>('portrait-state-move-up-${definition.id}'),
            onPressed: !isLocked && canMoveUp ? onMoveUp : null,
            tooltip: 'Monter ${definition.displayName}',
            icon: const Icon(CupertinoIcons.arrow_up),
          ),
          PokeMapIconButton(
            key: ValueKey<String>('portrait-state-move-down-${definition.id}'),
            onPressed: !isLocked && canMoveDown ? onMoveDown : null,
            tooltip: 'Descendre ${definition.displayName}',
            icon: const Icon(CupertinoIcons.arrow_down),
          ),
          PokeMapIconButton(
            key: ValueKey<String>('portrait-state-rename-${definition.id}'),
            onPressed: isLocked ? null : onRename,
            tooltip: 'Renommer ${definition.displayName}',
            icon: const Icon(CupertinoIcons.pencil),
          ),
          PokeMapIconButton(
            key: ValueKey<String>('portrait-state-delete-${definition.id}'),
            onPressed: isLocked ? null : onDelete,
            tooltip: 'Supprimer ${definition.displayName}',
            variant: PokeMapIconButtonVariant.danger,
            icon: const Icon(CupertinoIcons.trash),
          ),
        ],
      ),
    );
  }
}

final class PortraitStateDeleteDecision {
  const PortraitStateDeleteDecision({
    required this.resolution,
    this.replacementId,
  });

  final PortraitStateDeleteResolution resolution;
  final String? replacementId;
}

Future<PortraitStateDeleteDecision?> showPortraitStateDeleteDialog({
  required BuildContext context,
  required ProjectManifest project,
  required String stateLabel,
  required PortraitStateDeletePlan plan,
}) {
  PortraitStateDeleteResolution? resolution = plan.requiresResolution
      ? null
      : PortraitStateDeleteResolution.clear;
  var replacementId = plan.replacementCandidates.firstOrNull?.id;
  return showDialog<PortraitStateDeleteDecision>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => PokeMapDialog(
        key: const ValueKey<String>('portrait-state-delete-dialog'),
        title: 'Supprimer $stateLabel',
        icon: CupertinoIcons.trash,
        maxWidth: 580,
        footer: Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            PokeMapButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              variant: PokeMapButtonVariant.secondary,
              child: const Text('Annuler'),
            ),
            PokeMapButton(
              key: const ValueKey<String>('portrait-state-delete-confirm'),
              onPressed:
                  resolution == null ||
                      resolution == PortraitStateDeleteResolution.replace &&
                          replacementId == null
                  ? null
                  : () => Navigator.of(dialogContext).pop(
                      PortraitStateDeleteDecision(
                        resolution: resolution!,
                        replacementId:
                            resolution == PortraitStateDeleteResolution.replace
                            ? replacementId
                            : null,
                      ),
                    ),
              variant: PokeMapButtonVariant.danger,
              child: const Text('Supprimer définitivement'),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 460),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  plan.dependencies.isEmpty
                      ? 'Cette expression n’est utilisée par aucun portrait ou dialogue.'
                      : '${plan.dependencies.length} références seront modifiées. Vérifiez-les avant de choisir.',
                  style: TextStyle(
                    color: context.pokeMapColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                if (plan.dependencies.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  PokeMapPanel(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        for (
                          var index = 0;
                          index < plan.dependencies.length;
                          index++
                        ) ...[
                          _PortraitStateDependencyRow(
                            project: project,
                            dependency: plan.dependencies[index],
                          ),
                          if (index != plan.dependencies.length - 1)
                            Divider(
                              color: context.pokeMapColors.divider,
                              height: 18,
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
                if (plan.requiresResolution) ...[
                  const SizedBox(height: 16),
                  const PokeMapSectionHeader(
                    title: 'Traitement des références',
                    description:
                        'Effacez les portraits liés ou remplacez-les partout par une autre expression.',
                  ),
                  const SizedBox(height: 8),
                  PokeMapSegmentedTabs(
                    tabs: [
                      PokeMapSegmentedTab(
                        key: const ValueKey<String>(
                          'portrait-state-delete-resolution-clear',
                        ),
                        label: 'Effacer les références',
                        selected:
                            resolution == PortraitStateDeleteResolution.clear,
                        icon: CupertinoIcons.clear_circled,
                        onTap: () => setDialogState(
                          () =>
                              resolution = PortraitStateDeleteResolution.clear,
                        ),
                      ),
                      PokeMapSegmentedTab(
                        key: const ValueKey<String>(
                          'portrait-state-delete-resolution-replace',
                        ),
                        label: 'Remplacer partout',
                        selected:
                            resolution == PortraitStateDeleteResolution.replace,
                        icon: CupertinoIcons.arrow_2_circlepath,
                        onTap: plan.replacementCandidates.isEmpty
                            ? null
                            : () => setDialogState(
                                () => resolution =
                                    PortraitStateDeleteResolution.replace,
                              ),
                      ),
                    ],
                  ),
                  if (resolution == PortraitStateDeleteResolution.replace) ...[
                    const SizedBox(height: 12),
                    PokeMapDropdownField<String>(
                      label: 'Expression de remplacement',
                      value: replacementId ?? '',
                      items: [
                        for (final candidate in plan.replacementCandidates)
                          PokeMapDropdownItem<String>(
                            value: candidate.id,
                            label: candidate.displayName,
                          ),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => replacementId = value),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _PortraitStateDependencyRow extends StatelessWidget {
  const _PortraitStateDependencyRow({
    required this.project,
    required this.dependency,
  });

  final ProjectManifest project;
  final PortraitStateDeleteDependency dependency;

  @override
  Widget build(BuildContext context) {
    final isDialogue = dependency.sourceKind == 'dialogue';
    final label = isDialogue ? 'Dialogue' : 'Personnage';
    final name = isDialogue
        ? project.dialogues
              .where((entry) => entry.id == dependency.sourceId)
              .firstOrNull
              ?.name
        : project.characters
              .where((entry) => entry.id == dependency.sourceId)
              .firstOrNull
              ?.name;
    return Row(
      children: [
        Icon(
          isDialogue
              ? CupertinoIcons.chat_bubble_2_fill
              : CupertinoIcons.person,
          size: 16,
          color: context.pokeMapColors.warning,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            '$label · ${name ?? dependency.sourceId}',
            style: TextStyle(
              color: context.pokeMapColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
