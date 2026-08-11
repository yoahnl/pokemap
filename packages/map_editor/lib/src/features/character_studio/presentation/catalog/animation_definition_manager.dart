import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../application/character_animation_definition_use_cases.dart';
import '../../../../theme/theme.dart';
import '../../../../ui/design_system/design_system.dart';

typedef AnimationDefinitionCreateCallback =
    Future<void> Function(String label, CharacterCustomAnimationMode mode);
typedef AnimationDefinitionUpdateCallback =
    Future<void> Function(
      String id,
      String? label,
      CharacterCustomAnimationMode? mode,
    );
typedef AnimationDefinitionsReorderCallback =
    Future<void> Function(List<String> orderedIds);
typedef AnimationDefinitionDeletePreviewCallback =
    Future<AnimationDefinitionDeletePlan?> Function(String id);
typedef AnimationDefinitionDeleteCallback =
    Future<void> Function(
      String id,
      AnimationDefinitionDeleteResolution resolution,
      String? replacementId,
    );

class AnimationDefinitionManager extends StatefulWidget {
  const AnimationDefinitionManager({
    super.key,
    required this.project,
    required this.isSaving,
    required this.onCreate,
    required this.onUpdate,
    required this.onReorder,
    required this.onPreviewDelete,
    required this.onDelete,
    this.createImmediately = false,
  });

  final ProjectManifest project;
  final bool isSaving;
  final AnimationDefinitionCreateCallback onCreate;
  final AnimationDefinitionUpdateCallback onUpdate;
  final AnimationDefinitionsReorderCallback onReorder;
  final AnimationDefinitionDeletePreviewCallback onPreviewDelete;
  final AnimationDefinitionDeleteCallback onDelete;
  final bool createImmediately;

  @override
  State<AnimationDefinitionManager> createState() =>
      _AnimationDefinitionManagerState();
}

class _AnimationDefinitionManagerState
    extends State<AnimationDefinitionManager> {
  bool _isBusy = false;
  String? _feedback;

  bool get _locked => widget.isSaving || _isBusy;

  @override
  void initState() {
    super.initState();
    if (widget.createImmediately) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_locked) _create();
      });
    }
  }

  List<CharacterCustomAnimationDefinition> get _customDefinitions {
    return widget.project.characterStudioCatalog.customAnimationDefinitions
        .toList()
      ..sort((left, right) {
        final order = left.sortOrder.compareTo(right.sortOrder);
        return order != 0 ? order : left.id.compareTo(right.id);
      });
  }

  @override
  Widget build(BuildContext context) {
    final custom = _customDefinitions;
    return ListView(
      key: const ValueKey<String>('animation-definition-manager'),
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PokeMapIconTile(
              icon: CupertinoIcons.play_rectangle_fill,
              tone: PokeMapTone.cinematic,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Définitions d’animation',
                    style: TextStyle(
                      color: context.pokeMapColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Base, Marche et Course sont communes au moteur. Les autres sont libres pour tout le projet.',
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
              key: const ValueKey<String>('animation-definition-create'),
              onPressed: _locked ? null : _create,
              size: PokeMapButtonSize.small,
              leading: const Icon(CupertinoIcons.add),
              child: const Text('Animation custom'),
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
        const SizedBox(height: 18),
        const PokeMapSectionHeader(
          title: 'Animations système',
          description:
              'Leur identité est stable. Base est requise ; Marche et Course restent optionnelles.',
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < _systemDefinitions.length; index++) ...[
          _SystemDefinitionCard(
            definition: _systemDefinitions[index],
            coverage: _systemCoverage(_systemDefinitions[index].state),
            characterCount: widget.project.characters.length,
          ),
          if (index != _systemDefinitions.length - 1) const SizedBox(height: 8),
        ],
        const SizedBox(height: 18),
        const PokeMapSectionHeader(
          title: 'Animations custom',
          description:
              'L’ordre, le nom et le mode définis ici s’appliquent à tous les personnages.',
        ),
        const SizedBox(height: 8),
        if (custom.isEmpty)
          const PokeMapEmptyState(
            title: 'Aucune animation custom',
            description:
                'Ajoutez une définition globale avant de remplir ses clips.',
            icon: Icon(CupertinoIcons.sparkles),
            compact: true,
          )
        else
          for (var index = 0; index < custom.length; index++) ...[
            _CustomDefinitionCard(
              definition: custom[index],
              coverage: _customCoverage(custom[index].id),
              characterCount: widget.project.characters.length,
              isLocked: _locked,
              canMoveUp: index > 0,
              canMoveDown: index < custom.length - 1,
              onMoveUp: () => _move(index, -1),
              onMoveDown: () => _move(index, 1),
              onEdit: () => _edit(custom[index]),
              onDelete: () => _delete(custom[index]),
            ),
            if (index != custom.length - 1) const SizedBox(height: 8),
          ],
      ],
    );
  }

  int _systemCoverage(CharacterAnimationState state) {
    return widget.project.characters
        .where(
          (character) => character.animations.any(
            (animation) =>
                animation.state == state && animation.frames.isNotEmpty,
          ),
        )
        .length;
  }

  int _customCoverage(String definitionId) {
    return widget.project.characters
        .where(
          (character) => character.customAnimations.any(
            (animation) => animation.definitionId == definitionId,
          ),
        )
        .length;
  }

  Future<void> _create() async {
    final result = await _showDefinitionDialog(
      context,
      project: widget.project,
      title: 'Nouvelle animation custom',
    );
    if (result == null || !mounted) return;
    await _run(
      () => widget.onCreate(result.label, result.mode),
      'L’animation « ${result.label} » a été créée.',
    );
  }

  Future<void> _edit(CharacterCustomAnimationDefinition definition) async {
    final result = await _showDefinitionDialog(
      context,
      project: widget.project,
      title: 'Modifier ${definition.displayName}',
      definition: definition,
      referenceCount: _customCoverage(definition.id),
    );
    if (result == null || !mounted) return;
    final label = result.label == definition.displayName ? null : result.label;
    final mode = result.mode == definition.mode ? null : result.mode;
    if (label == null && mode == null) return;
    await _run(
      () => widget.onUpdate(definition.id, label, mode),
      'La définition « ${result.label} » a été mise à jour.',
    );
  }

  Future<void> _move(int index, int offset) async {
    final ids = _customDefinitions.map((definition) => definition.id).toList();
    final target = index + offset;
    if (target < 0 || target >= ids.length) return;
    final moved = ids.removeAt(index);
    ids.insert(target, moved);
    await _run(
      () => widget.onReorder(ids),
      'L’ordre global des animations a été mis à jour.',
    );
  }

  Future<void> _delete(CharacterCustomAnimationDefinition definition) async {
    setState(() => _isBusy = true);
    final plan = await widget.onPreviewDelete(definition.id);
    if (!mounted) return;
    setState(() => _isBusy = false);
    if (plan == null) return;
    final decision = await _showDeleteDialog(
      context,
      project: widget.project,
      definition: definition,
      plan: plan,
    );
    if (decision == null || !mounted) return;
    await _run(
      () => widget.onDelete(
        definition.id,
        decision.resolution,
        decision.replacementId,
      ),
      'L’animation « ${definition.displayName} » a été supprimée.',
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

final class _SystemAnimationDefinition {
  const _SystemAnimationDefinition({
    required this.id,
    required this.label,
    required this.state,
    required this.required,
  });

  final String id;
  final String label;
  final CharacterAnimationState state;
  final bool required;
}

const _systemDefinitions = <_SystemAnimationDefinition>[
  _SystemAnimationDefinition(
    id: 'base',
    label: 'Base',
    state: CharacterAnimationState.idle,
    required: true,
  ),
  _SystemAnimationDefinition(
    id: 'walk',
    label: 'Marche',
    state: CharacterAnimationState.walk,
    required: false,
  ),
  _SystemAnimationDefinition(
    id: 'run',
    label: 'Course',
    state: CharacterAnimationState.run,
    required: false,
  ),
];

class _SystemDefinitionCard extends StatelessWidget {
  const _SystemDefinitionCard({
    required this.definition,
    required this.coverage,
    required this.characterCount,
  });

  final _SystemAnimationDefinition definition;
  final int coverage;
  final int characterCount;

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      key: ValueKey<String>('animation-definition-card-${definition.id}'),
      child: Row(
        children: [
          PokeMapIconTile(
            icon: definition.required
                ? CupertinoIcons.play_fill
                : CupertinoIcons.play,
            tone: definition.required ? PokeMapTone.success : PokeMapTone.info,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  definition.label,
                  style: TextStyle(
                    color: context.pokeMapColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  definition.required
                      ? 'Système · Directionnelle · Requise'
                      : 'Système · Directionnelle · Optionnelle',
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
            variant: coverage == characterCount && characterCount > 0
                ? PokeMapBadgeVariant.success
                : definition.required
                ? PokeMapBadgeVariant.error
                : PokeMapBadgeVariant.warning,
          ),
          const SizedBox(width: 8),
          const PokeMapBadge(
            label: 'Verrouillée',
            variant: PokeMapBadgeVariant.neutral,
          ),
        ],
      ),
    );
  }
}

class _CustomDefinitionCard extends StatelessWidget {
  const _CustomDefinitionCard({
    required this.definition,
    required this.coverage,
    required this.characterCount,
    required this.isLocked,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onEdit,
    required this.onDelete,
  });

  final CharacterCustomAnimationDefinition definition;
  final int coverage;
  final int characterCount;
  final bool isLocked;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      key: ValueKey<String>('animation-definition-card-${definition.id}'),
      child: Row(
        children: [
          const PokeMapIconTile(
            icon: CupertinoIcons.sparkles,
            tone: PokeMapTone.cinematic,
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
                  '${definition.id} · ${_modeLabel(definition.mode)}',
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
            variant: coverage == characterCount && characterCount > 0
                ? PokeMapBadgeVariant.success
                : PokeMapBadgeVariant.warning,
          ),
          const SizedBox(width: 8),
          PokeMapIconButton(
            key: ValueKey<String>(
              'animation-definition-move-up-${definition.id}',
            ),
            onPressed: !isLocked && canMoveUp ? onMoveUp : null,
            tooltip: 'Monter ${definition.displayName}',
            icon: const Icon(CupertinoIcons.arrow_up),
          ),
          PokeMapIconButton(
            key: ValueKey<String>(
              'animation-definition-move-down-${definition.id}',
            ),
            onPressed: !isLocked && canMoveDown ? onMoveDown : null,
            tooltip: 'Descendre ${definition.displayName}',
            icon: const Icon(CupertinoIcons.arrow_down),
          ),
          PokeMapIconButton(
            key: ValueKey<String>('animation-definition-edit-${definition.id}'),
            onPressed: isLocked ? null : onEdit,
            tooltip: 'Modifier ${definition.displayName}',
            icon: const Icon(CupertinoIcons.pencil),
          ),
          PokeMapIconButton(
            key: ValueKey<String>(
              'animation-definition-delete-${definition.id}',
            ),
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

final class _DefinitionDialogResult {
  const _DefinitionDialogResult({required this.label, required this.mode});

  final String label;
  final CharacterCustomAnimationMode mode;
}

Future<_DefinitionDialogResult?> _showDefinitionDialog(
  BuildContext context, {
  required ProjectManifest project,
  required String title,
  CharacterCustomAnimationDefinition? definition,
  int referenceCount = 0,
}) async {
  final controller = TextEditingController(text: definition?.displayName);
  var mode = definition?.mode ?? CharacterCustomAnimationMode.directional;
  var label = controller.text.trim();
  final navigator = Navigator.of(context, rootNavigator: true);
  final route = DialogRoute<_DefinitionDialogResult>(
    context: context,
    barrierDismissible: false,
    themes: InheritedTheme.capture(from: context, to: navigator.context),
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        final validation = _definitionValidation(
          project,
          label,
          ignoredId: definition?.id,
        );
        final modeMigrationBlocked =
            definition != null && mode != definition.mode && referenceCount > 0;
        final changed =
            definition == null ||
            label != definition.displayName ||
            mode != definition.mode;
        return PokeMapDialog(
          title: title,
          icon: CupertinoIcons.sparkles,
          maxWidth: 560,
          footer: Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            children: [
              PokeMapButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                variant: PokeMapButtonVariant.secondary,
                child: const Text('Annuler'),
              ),
              PokeMapButton(
                key: ValueKey<String>(
                  definition == null
                      ? 'animation-definition-create-confirm'
                      : 'animation-definition-update-confirm',
                ),
                onPressed:
                    validation == null && !modeMigrationBlocked && changed
                    ? () => Navigator.of(
                        dialogContext,
                      ).pop(_DefinitionDialogResult(label: label, mode: mode))
                    : null,
                child: Text(definition == null ? 'Créer' : 'Enregistrer'),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PokeMapTextField(
                label: 'Nom affiché',
                controller: controller,
                fieldKey: const ValueKey<String>(
                  'animation-definition-name-field',
                ),
                errorText: validation,
                autofocus: true,
                onChanged: (value) =>
                    setDialogState(() => label = value.trim()),
              ),
              const SizedBox(height: 14),
              Text(
                'Mode des clips',
                style: TextStyle(
                  color: context.pokeMapColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              PokeMapSegmentedTabs(
                tabs: [
                  PokeMapSegmentedTab(
                    key: const ValueKey<String>(
                      'animation-definition-mode-directional',
                    ),
                    label: 'N / S / E / O',
                    selected: mode == CharacterCustomAnimationMode.directional,
                    icon: CupertinoIcons.compass,
                    onTap: () => setDialogState(
                      () => mode = CharacterCustomAnimationMode.directional,
                    ),
                  ),
                  PokeMapSegmentedTab(
                    key: const ValueKey<String>(
                      'animation-definition-mode-single',
                    ),
                    label: 'Slot unique',
                    selected: mode == CharacterCustomAnimationMode.single,
                    icon: CupertinoIcons.square,
                    onTap: () => setDialogState(
                      () => mode = CharacterCustomAnimationMode.single,
                    ),
                  ),
                ],
              ),
              if (modeMigrationBlocked) ...[
                const SizedBox(height: 12),
                const PokeMapActionBanner(
                  title: 'Migration du mode requise',
                  message:
                      'Retirez d’abord les clips existants dans la matrice.',
                  tone: PokeMapTone.warning,
                ),
              ],
            ],
          ),
        );
      },
    ),
  );
  final result = await navigator.push(route);
  await route.completed;
  controller.dispose();
  return result;
}

String? _definitionValidation(
  ProjectManifest project,
  String label, {
  String? ignoredId,
}) {
  if (label.isEmpty) return 'Le nom est obligatoire.';
  final id = _slug(label);
  if (_reservedAnimationIds.contains(id)) {
    return 'Identifiant réservé au système.';
  }
  if (project.characterStudioCatalog.customAnimationDefinitions.any(
    (definition) => definition.id == id && definition.id != ignoredId,
  )) {
    return 'Une animation utilise déjà cet identifiant.';
  }
  return null;
}

const _reservedAnimationIds = <String>{'base', 'idle', 'walk', 'run'};

String _slug(String value) {
  final normalized = value.trim().toLowerCase().replaceAll(
    RegExp(r'[^a-z0-9]+'),
    '-',
  );
  return normalized.replaceAll(RegExp(r'^-+|-+$'), '');
}

String _modeLabel(CharacterCustomAnimationMode mode) => switch (mode) {
  CharacterCustomAnimationMode.single => 'Slot unique',
  CharacterCustomAnimationMode.directional => 'N / S / E / O',
};

final class _DeleteDecision {
  const _DeleteDecision({required this.resolution, this.replacementId});

  final AnimationDefinitionDeleteResolution resolution;
  final String? replacementId;
}

Future<_DeleteDecision?> _showDeleteDialog(
  BuildContext context, {
  required ProjectManifest project,
  required CharacterCustomAnimationDefinition definition,
  required AnimationDefinitionDeletePlan plan,
}) {
  AnimationDefinitionDeleteResolution? resolution = plan.requiresResolution
      ? null
      : AnimationDefinitionDeleteResolution.clear;
  var replacementId = plan.replacementCandidates.firstOrNull?.id;
  return showDialog<_DeleteDecision>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => PokeMapDialog(
        key: const ValueKey<String>('animation-definition-delete-dialog'),
        title: 'Supprimer ${definition.displayName}',
        icon: CupertinoIcons.trash,
        maxWidth: 580,
        footer: Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          children: [
            PokeMapButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              variant: PokeMapButtonVariant.secondary,
              child: const Text('Annuler'),
            ),
            PokeMapButton(
              key: const ValueKey<String>(
                'animation-definition-delete-confirm',
              ),
              onPressed:
                  resolution == null ||
                      resolution ==
                              AnimationDefinitionDeleteResolution.replace &&
                          replacementId == null
                  ? null
                  : () => Navigator.of(dialogContext).pop(
                      _DeleteDecision(
                        resolution: resolution!,
                        replacementId:
                            resolution ==
                                AnimationDefinitionDeleteResolution.replace
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
              children: [
                Text(
                  plan.dependencies.isEmpty
                      ? 'Aucun clip ne référence cette définition.'
                      : '${plan.dependencies.length} clips seront modifiés.',
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
                        for (final dependency in plan.dependencies)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                const Icon(CupertinoIcons.person_crop_circle),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Personnage · ${_characterName(project, dependency.sourceId)}',
                                    style: TextStyle(
                                      color: context.pokeMapColors.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                if (plan.requiresResolution) ...[
                  const SizedBox(height: 16),
                  PokeMapSegmentedTabs(
                    tabs: [
                      PokeMapSegmentedTab(
                        key: const ValueKey<String>(
                          'animation-definition-delete-resolution-clear',
                        ),
                        label: 'Effacer les clips',
                        selected:
                            resolution ==
                            AnimationDefinitionDeleteResolution.clear,
                        icon: CupertinoIcons.clear_circled,
                        onTap: () => setDialogState(
                          () => resolution =
                              AnimationDefinitionDeleteResolution.clear,
                        ),
                      ),
                      PokeMapSegmentedTab(
                        key: const ValueKey<String>(
                          'animation-definition-delete-resolution-replace',
                        ),
                        label: 'Remplacer partout',
                        selected:
                            resolution ==
                            AnimationDefinitionDeleteResolution.replace,
                        icon: CupertinoIcons.arrow_2_circlepath,
                        onTap: plan.replacementCandidates.isEmpty
                            ? null
                            : () => setDialogState(
                                () => resolution =
                                    AnimationDefinitionDeleteResolution.replace,
                              ),
                      ),
                    ],
                  ),
                  if (resolution ==
                      AnimationDefinitionDeleteResolution.replace) ...[
                    const SizedBox(height: 12),
                    PokeMapDropdownField<String>(
                      label: 'Animation de remplacement',
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

String _characterName(ProjectManifest project, String id) {
  return project.characters
          .where((character) => character.id == id)
          .firstOrNull
          ?.name ??
      id;
}
