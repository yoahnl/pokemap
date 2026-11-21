import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import '../../shared/localization/studio_locale.dart';
import '../../shared/widgets/avelune_studio_brand.dart';
import '../../shell/studio_rail.dart';
import '../../shell/studio_top_bar.dart';
import '../settings/studio_settings_page.dart';

class StudioHomeFrame extends StatefulWidget {
  const StudioHomeFrame({
    super.key,
    required this.child,
    required this.search,
    required this.onSearch,
    required this.destinations,
    this.projectName,
    this.busy = false,
    this.onClose,
  });
  final Widget child;
  final TextEditingController search;
  final ValueChanged<String> onSearch;
  final Map<String, VoidCallback> destinations;
  final String? projectName;
  final bool busy;
  final VoidCallback? onClose;

  @override
  State<StudioHomeFrame> createState() => _StudioHomeFrameState();
}

class _StudioHomeFrameState extends State<StudioHomeFrame> {
  var _showSettings = false;

  VoidCallback? _sectionAction(StudioRailSection section) {
    if (widget.busy) return null;
    return switch (section) {
      StudioRailSection.settings =>
        widget.destinations[section.name] ??
            () => setState(() => _showSettings = true),
      StudioRailSection.home when _showSettings => () => setState(
        () => _showSettings = false,
      ),
      _ => widget.destinations[section.name],
    };
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final compact = bounds.maxWidth < 1200;
      final colors = Theme.of(context).colorScheme;
      final projectName = widget.projectName;
      final onClose = widget.onClose;
      return Material(
        child: Column(
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: studioTopBarHeight),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                border: Border(
                  bottom: BorderSide(color: colors.outlineVariant),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: StudioSpacing.xl,
                vertical: 2,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: bounds.maxWidth < 650
                        ? 48
                        : compact
                        ? 250
                        : 300,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AveluneStudioBrand(compact: bounds.maxWidth < 650),
                    ),
                  ),
                  if (projectName != null && bounds.maxWidth >= 700) ...[
                    const SizedBox(width: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Text(
                        projectName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 18),
                  ],
                  Expanded(
                    child: StudioSearchField(
                      controller: widget.search,
                      label: 'Rechercher dans vos projets et cartes',
                      onChanged: widget.onSearch,
                    ),
                  ),
                  if (onClose != null) ...[
                    const SizedBox(width: StudioSpacing.s),
                    StudioTool(
                      key: const ValueKey('studio-project-home-close'),
                      label: context.l10n.homeCloseProject,
                      icon: Icons.folder_off_outlined,
                      onPressed: widget.busy ? null : onClose,
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StudioRail(
                    section: _showSettings
                        ? StudioRailSection.settings
                        : StudioRailSection.home,
                    sectionAction: _sectionAction,
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: _showSettings ? 1 : 0,
                      sizing: StackFit.expand,
                      children: [
                        TickerMode(
                          enabled: !_showSettings,
                          child: ExcludeFocus(
                            excluding: _showSettings,
                            child: widget.child,
                          ),
                        ),
                        if (_showSettings) const StudioSettingsPage(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
