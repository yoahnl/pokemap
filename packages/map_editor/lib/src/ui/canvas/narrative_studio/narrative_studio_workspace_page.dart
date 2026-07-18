import 'package:flutter/cupertino.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';
import 'narrative_studio_route_presentation.dart';

const narrativeStudioWorkspaceContextKey =
    ValueKey<String>('narrative-studio-workspace-context');

/// Shared inner page frame for one Narrative Studio workspace.
///
/// Workspaces own the real breadcrumb detail, real actions and business body.
/// This widget only aligns those elements with the shared product shell.
class NarrativeStudioWorkspacePage extends StatelessWidget {
  const NarrativeStudioWorkspacePage({
    super.key,
    required this.presentation,
    required this.body,
    this.actions = const [],
    this.leading,
  });

  final NarrativeStudioRoutePresentation presentation;
  final Widget body;
  final List<Widget> actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final breadcrumb = <String>[
      'Narrative Studio',
      ...presentation.breadcrumbLabels,
    ].join('  /  ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          key: narrativeStudioWorkspaceContextKey,
          height: 52,
          child: PokeMapToolbarSurface(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                leading ??
                    Icon(
                      CupertinoIcons.house,
                      size: 14,
                      color: colors.textMuted,
                    ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    breadcrumb,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.brandPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                for (var index = 0; index < actions.length; index++) ...[
                  if (index > 0) const SizedBox(width: 8),
                  actions[index],
                ],
              ],
            ),
          ),
        ),
        Expanded(child: body),
      ],
    );
  }
}
