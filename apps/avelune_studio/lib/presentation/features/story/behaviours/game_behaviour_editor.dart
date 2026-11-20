import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_errors.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_name_field.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_milestones.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

import 'game_behaviour_cases.dart';
import 'game_behaviour_conditions.dart';
import 'game_behaviour_context.dart';
import 'game_behaviour_repeat.dart';
import 'game_behaviour_scene.dart';
import 'game_behaviour_simulation.dart';
import 'game_behaviour_when.dart';

class GameBehaviourEditor extends StatefulWidget {
  const GameBehaviourEditor({
    super.key,
    required this.binding,
    required this.editable,
    this.allowCreation = true,
  });

  final MapBuilderStoryBinding binding;
  final bool editable;
  final bool allowCreation;

  @override
  State<GameBehaviourEditor> createState() => _GameBehaviourEditorState();
}

class _GameBehaviourEditorState extends State<GameBehaviourEditor> {
  bool _contextOpen = false;

  MapBuilderStoryBinding get binding => widget.binding;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final record = binding.selectedBehaviour;
    final element = binding.selected!;
    final details = record != null && _contextOpen
        ? GameBehaviourContext(
            binding: binding,
            record: record,
            element: element,
          )
        : null;
    final detailsBreakpoint =
        680 * MediaQuery.textScalerOf(context).scale(12) / 12;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioPageHeader(
          title: record == null
              ? l10n.storyNoBehaviour
              : record.name.trim().isEmpty
              ? l10n.behavioursUnnamed
              : record.name,
          description: l10n.triggersEditorHint,
          compact: true,
          alignActionsToEnd: true,
          actions: [
            if (record != null)
              MergeSemantics(
                key: const ValueKey('story-trigger-context-toggle'),
                child: Semantics(
                  expanded: _contextOpen,
                  child: StudioButton(
                    label: l10n.triggersContext,
                    icon: _contextOpen ? Icons.info : Icons.info_outline,
                    variant: StudioButtonVariant.quiet,
                    onPressed: () =>
                        setState(() => _contextOpen = !_contextOpen),
                  ),
                ),
              ),
          ],
        ),
        LayoutBuilder(
          builder: (context, area) {
            final inline = area.maxWidth >= detailsBreakpoint;
            return Flex(
              direction: inline ? Axis.horizontal : Axis.vertical,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: inline
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.stretch,
              children: [
                Flexible(
                  flex: inline ? 1 : 0,
                  fit: FlexFit.tight,
                  child: _commands(context),
                ),
                if (details != null) ...[
                  SizedBox(
                    width: inline ? StudioSpacing.l : 0,
                    height: inline ? 0 : StudioSpacing.m,
                  ),
                  SizedBox(width: inline ? 190 : null, child: details),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _block(BuildContext context, String section, Widget content) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: StudioSpacing.m),
      child: StudioPanel(
        key: ValueKey('story-trigger-block-$section'),
        compact: true,
        title: switch (section) {
          'when' => l10n.storyWhen,
          'if' => l10n.storyIf,
          'then' => l10n.storyThen,
          _ => l10n.triggersRepeat,
        },
        icon: switch (section) {
          'when' => Icons.bolt_outlined,
          'if' => Icons.call_split,
          'then' => Icons.account_tree_outlined,
          _ => Icons.repeat,
        },
        accent: switch (section) {
          'when' => StudioAccent.halo,
          'if' => StudioAccent.fog,
          'then' => StudioAccent.water,
          _ => StudioAccent.firefly,
        },
        children: [content],
      ),
    );
  }

  Widget _commands(BuildContext context) {
    final l10n = context.l10n;
    final record = binding.selectedBehaviour;
    final element = binding.selected!;
    final editable =
        widget.editable &&
        !binding.editingBlocked &&
        binding.ready &&
        binding.editing?.problem == null;
    return KeyedSubtree(
      key: ValueKey('map-story-editor-${record?.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (binding.error ?? binding.repairError ?? binding.editing?.problem
              case final error?)
            StudioNotice(mapBuilderStoryError(error, l10n), isError: true),
          if (!binding.ready)
            StudioNotice(
              binding.preparing ? l10n.storyPreparing : l10n.storyNotPrepared,
            ),
          GameBehaviourCases(
            binding: binding,
            element: element,
            record: record,
            editable: editable,
            allowCreation: widget.allowCreation,
          ),
          if (record != null) ...[
            const SizedBox(height: StudioSpacing.m),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: MapBuilderNameField(
                    key: ValueKey('map-story-behaviour-name-${record.id}'),
                    value: record.name,
                    label: l10n.storyBehaviourNameField,
                    enabled: editable,
                    onSubmit: (value) async =>
                        binding.renameBehaviour(record, value),
                  ),
                ),
                const SizedBox(width: StudioSpacing.l),
                Expanded(
                  flex: 2,
                  child: StudioToggleRow(
                    key: const ValueKey('map-story-behaviour-active'),
                    label: l10n.storyBehaviourActive,
                    value: record.enabledOrNull == true,
                    onChanged: editable
                        ? (value) => binding.setActive(record, value)
                        : null,
                  ),
                ),
              ],
            ),
            if (record.sceneId == null ||
                binding.sceneOf(record.sceneId!) == null)
              StudioBadge(l10n.triggersIncomplete, tone: StudioTone.warning),
            _block(
              context,
              'when',
              GameBehaviourWhen(
                binding: binding,
                record: record,
                element: element,
                editable: editable,
              ),
            ),
            _block(
              context,
              'if',
              GameBehaviourConditions(
                binding: binding,
                record: record,
                editable: editable,
              ),
            ),
            _block(
              context,
              'then',
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GameBehaviourScene(
                    binding: binding,
                    record: record,
                    element: element,
                    editable: editable,
                    sceneRepairable:
                        widget.editable &&
                        !binding.editingBlocked &&
                        binding.ready &&
                        binding.editing?.canRepairScene == true,
                  ),
                  const SizedBox(height: StudioSpacing.m),
                  MapBuilderStoryMilestoneField(
                    key: ValueKey('map-story-milestone-${record.id}'),
                    binding: binding,
                    record: record,
                    editable: editable,
                  ),
                ],
              ),
            ),
            _block(
              context,
              'repeat',
              GameBehaviourRepeat(
                binding: binding,
                record: record,
                editable: editable,
              ),
            ),
            const SizedBox(height: StudioSpacing.l),
            GameBehaviourSimulation(binding: binding, record: record),
            const SizedBox(height: StudioSpacing.l),
            Align(
              alignment: Alignment.centerLeft,
              child: StudioButton(
                key: const ValueKey('map-story-behaviour-delete'),
                variant: StudioButtonVariant.destructive,
                icon: Icons.delete_outline,
                label: l10n.storyDeleteBehaviour,
                onPressed: editable
                    ? () => binding.deleteBehaviour(record)
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
