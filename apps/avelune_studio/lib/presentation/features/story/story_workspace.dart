import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/story_workspace/application/story_workspace_state.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

import 'story_breadcrumb.dart';
import 'story_inspector.dart';
import 'story_navigation.dart';

typedef StoryPanelBuilder = Widget Function(Widget content, Widget inspector);

class StoryWorkspace extends StatefulWidget {
  const StoryWorkspace({
    super.key,
    required this.section,
    required this.onSelected,
    required this.editable,
    required this.builder,
    this.saveError,
  });

  final StorySection section;
  final ValueChanged<StorySection> onSelected;
  final bool editable;
  final String? saveError;
  final Widget Function(StoryPanelBuilder panels) builder;

  @override
  State<StoryWorkspace> createState() => _StoryWorkspaceState();
}

class _StoryWorkspaceState extends State<StoryWorkspace> {
  bool? _inspector;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final inline = constraints.maxWidth >= 1100;
      final visible = _inspector ?? inline;
      final l10n = context.l10n;
      return Row(
        key: const ValueKey('studio-story'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StoryNavigation(
            selected: widget.section,
            onSelected: widget.onSelected,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StoryBreadcrumb(section: widget.section),
                StudioPageHeader(
                  title: storySectionLabel(context, widget.section),
                  description: storySectionHint(context, widget.section),
                  compact: true,
                  alignActionsToEnd: true,
                  actions: [
                    StudioButton(
                      key: const ValueKey('story-toggle-inspector'),
                      label: visible ? l10n.inspectorHide : l10n.inspectorShow,
                      icon: visible ? Icons.chevron_right : Icons.chevron_left,
                      variant: StudioButtonVariant.quiet,
                      onPressed: () => setState(() => _inspector = !visible),
                    ),
                  ],
                ),
                if (!widget.editable)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: StudioSpacing.l,
                    ),
                    child: StudioNotice(
                      l10n.storyReadOnly,
                      key: const ValueKey('story-read-only'),
                    ),
                  ),
                if (widget.saveError case final reason?)
                  Padding(
                    padding: const EdgeInsets.all(StudioSpacing.l),
                    child: StudioNotice(
                      l10n.storySaveFailed(reason),
                      key: const ValueKey('story-save-error'),
                      isError: true,
                    ),
                  ),
                Expanded(
                  child: widget.builder(
                    (content, inspector) => LayoutBuilder(
                      builder: (context, area) => Stack(
                        children: [
                          Positioned.fill(
                            right: inline && visible ? 320 : 0,
                            child: Offstage(
                              offstage: !inline && visible,
                              child: content,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            bottom: 0,
                            width: inline ? 320 : area.maxWidth,
                            child: Offstage(
                              offstage: !visible,
                              child: StoryInspector(
                                key: const ValueKey('story-inspector'),
                                width: double.infinity,
                                child: inspector,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}
