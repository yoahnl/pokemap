import 'package:flutter/material.dart';
import '../inputs/studio_search_field.dart';
import 'studio_primary_navigation.dart';

class StudioApplicationFrame extends StatelessWidget {
  const StudioApplicationFrame({
    super.key,
    required this.child,
    required this.search,
    required this.onSearch,
    required this.onDestination,
    this.projectName,
    this.active = 'home',
    this.busy = false,
    this.canTest = false,
    this.onClose,
    this.searchFocusNode,
    this.headerActions,
  });
  final Widget child;
  final TextEditingController search;
  final ValueChanged<String> onSearch, onDestination;
  final String? projectName;
  final String active;
  final bool busy, canTest;
  final VoidCallback? onClose;
  final FocusNode? searchFocusNode;
  final Widget? headerActions;

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
                    child:
                        headerActions ??
                        StudioSearchField(
                          controller: search,
                          focusNode: searchFocusNode,
                          label: 'Rechercher dans vos projets et cartes',
                          onChanged: onSearch,
                        ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StudioPrimaryNavigation(
                    onDestination: onDestination,
                    projectName: projectName,
                    busy: busy,
                    canTest: canTest,
                    compact: compact,
                    active: active,
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
