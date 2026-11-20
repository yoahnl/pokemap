import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import '../../shared/localization/studio_language_menu.dart';
import 'studio_home_display_preferences.dart';
import 'studio_home_navigation.dart';

class StudioHomeFrame extends StatelessWidget {
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
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final compact = bounds.maxWidth < 1200;
      final colors = Theme.of(context).colorScheme;
      return Material(
        child: Column(
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: 64),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                border: Border(
                  bottom: BorderSide(color: colors.outlineVariant),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: bounds.maxWidth < 650
                        ? 48
                        : compact
                        ? 250
                        : 300,
                    height: 60,
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/home/avelune_symbol.png',
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                          semanticLabel: 'Symbole Avelune Studio',
                        ),
                        if (bounds.maxWidth >= 650) ...[
                          const SizedBox(width: 10),
                          Image.asset(
                            'assets/home/avelune_logo.png',
                            width: 184,
                            height: 54,
                            fit: BoxFit.contain,
                            semanticLabel: 'Avelune Studio',
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (projectName != null && bounds.maxWidth >= 700) ...[
                    const SizedBox(width: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Text(
                        projectName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 18),
                  ],
                  Expanded(
                    child: StudioSearchField(
                      controller: search,
                      label: 'Rechercher dans vos projets et cartes',
                      onChanged: onSearch,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const StudioLanguageMenu(),
                  const StudioDisplayPreferencesButton(),
                ],
              ),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StudioHomeNavigation(
                    destinations: destinations,
                    projectName: projectName,
                    busy: busy,
                    compact: compact,
                    onClose: onClose,
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
