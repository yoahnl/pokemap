import 'package:flutter/cupertino.dart';

import '../../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';
import 'narrative_studio_route_presentation.dart';

const narrativeStudioWorkspaceContextKey =
    ValueKey<String>('narrative-studio-workspace-context');
const narrativeStudioWorkspaceActionsScrollKey =
    ValueKey<String>('narrative-studio-workspace-actions-scroll');

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
      context.pokeMapL10n.narrativeStudio,
      ...presentation.breadcrumbLabels,
    ].join('  /  ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          key: narrativeStudioWorkspaceContextKey,
          constraints: const BoxConstraints(minHeight: 52),
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
                if (actions.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        key: narrativeStudioWorkspaceActionsScrollKey,
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: constraints.maxWidth,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              for (var index = 0;
                                  index < actions.length;
                                  index++) ...[
                                if (index > 0) const SizedBox(width: 8),
                                actions[index],
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
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
