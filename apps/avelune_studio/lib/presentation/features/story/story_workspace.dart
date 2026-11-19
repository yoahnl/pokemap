import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/story_workspace/application/story_workspace_state.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

import 'story_inspector.dart';
import 'story_navigation.dart';

const _inspectorWidth = 320.0;

typedef StoryPanelBuilder = Widget Function(Widget content, Widget inspector);

class StoryWorkspace extends StatefulWidget {
  const StoryWorkspace({
    super.key,
    required this.section,
    required this.onSelected,
    required this.editable,
    required this.builder,
    this.saveError,
    this.inspectorAvailable = true,
    this.verificationMarker,
  });

  final StorySection section;
  final ValueChanged<StorySection> onSelected;
  final bool editable;
  final String? saveError;
  final bool inspectorAvailable;
  final StudioBadge? verificationMarker;
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
      final contentHidden = !inline && visible;
      final inlineInspector = inline && visible && widget.inspectorAvailable;
      final l10n = context.l10n;
      return Row(
        key: const ValueKey('studio-story'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StoryNavigation(
            selected: widget.section,
            onSelected: widget.onSelected,
            verificationMarker: widget.verificationMarker,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.section != StorySection.behaviours)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: StudioPageHeader.section(
                            key: const ValueKey('story-section-header'),
                            title: storySectionLabel(context, widget.section),
                            actions: [
                              if (widget.section != StorySection.verification)
                                StudioButton(
                                  label: l10n.storyTabVerify,
                                  icon: Icons.info_outline,
                                  variant: StudioButtonVariant.quiet,
                                  onPressed: () => widget.onSelected(
                                    StorySection.verification,
                                  ),
                                ),
                              if (widget.inspectorAvailable)
                                StudioTool(
                                  key: const ValueKey('story-toggle-inspector'),
                                  label: visible
                                      ? l10n.inspectorHide
                                      : l10n.inspectorShow,
                                  icon: visible
                                      ? Icons.last_page
                                      : Icons.first_page,
                                  onPressed: () =>
                                      setState(() => _inspector = !visible),
                                ),
                            ],
                          ),
                        ),
                        if (inlineInspector)
                          SizedBox(
                            width: _inspectorWidth,
                            child: StudioPageHeader.section(
                              key: const ValueKey('story-inspector-header'),
                              title: l10n.inspectorTitle,
                            ),
                          ),
                      ],
                    ),
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
                    (content, inspector) => !widget.inspectorAvailable
                        ? content
                        : LayoutBuilder(
                            builder: (context, area) => Stack(
                              children: [
                                Positioned.fill(
                                  right: inlineInspector ? _inspectorWidth : 0,
                                  child: ExcludeFocus(
                                    excluding: contentHidden,
                                    child: Offstage(
                                      offstage: contentHidden,
                                      child: TooltipVisibility(
                                        visible:
                                            TooltipVisibility.of(context) &&
                                            !contentHidden,
                                        child: content,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  bottom: 0,
                                  width: inline
                                      ? _inspectorWidth
                                      : area.maxWidth,
                                  child: ExcludeFocus(
                                    excluding: !visible,
                                    child: Offstage(
                                      offstage: !visible,
                                      child: TooltipVisibility(
                                        visible:
                                            TooltipVisibility.of(context) &&
                                            visible,
                                        child: TickerMode(
                                          enabled: visible,
                                          child: StoryInspector(
                                            key: const ValueKey(
                                              'story-inspector',
                                            ),
                                            width: double.infinity,
                                            showTitle: !inline,
                                            child: inspector,
                                          ),
                                        ),
                                      ),
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
