import 'package:flutter/cupertino.dart';

import '../../../../l10n/l10n.dart';
import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';
import 'narrative_studio_destination.dart';
import 'narrative_studio_product_navigation.dart';

const narrativeStudioProductShellKey =
    ValueKey<String>('narrative-studio-product-shell');
const narrativeStudioProductShellHeaderKey =
    ValueKey<String>('narrative-studio-product-shell-header');
const narrativeStudioProductShellProjectKey =
    ValueKey<String>('narrative-studio-product-shell-project');
const narrativeStudioProductShellNavigationKey =
    ValueKey<String>('narrative-studio-product-shell-navigation');
const narrativeStudioProductShellWorkspaceKey =
    ValueKey<String>('narrative-studio-product-shell-workspace');

/// Provider-free rail geometry selected only from the available viewport.
///
/// Keeping the policy public and immutable lets accessibility tests prove every
/// breakpoint without depending on a rendered feature workspace.
@immutable
final class NarrativeStudioRailPresentation {
  const NarrativeStudioRailPresentation({
    required this.width,
    required this.collapsed,
  });

  final double width;
  final bool collapsed;
}

/// Returns the canonical desktop rail presentation for Narrative Studio.
NarrativeStudioRailPresentation narrativeStudioRailPresentation(
  double viewportWidth,
) {
  if (viewportWidth < 900) {
    return const NarrativeStudioRailPresentation(width: 72, collapsed: true);
  }
  if (viewportWidth < 1100) {
    return const NarrativeStudioRailPresentation(width: 148, collapsed: false);
  }
  if (viewportWidth < 1480) {
    return const NarrativeStudioRailPresentation(width: 168, collapsed: false);
  }
  if (viewportWidth < 1672) {
    return const NarrativeStudioRailPresentation(width: 176, collapsed: false);
  }
  return const NarrativeStudioRailPresentation(width: 191, collapsed: false);
}

/// Shared outer product chrome for Narrative Studio.
///
/// The shell owns geometry only: product header, optional project/status slots,
/// navigation and the workspace slot. It deliberately contains no business
/// provider, service or workspace-specific grid.
class NarrativeStudioProductShell extends StatelessWidget {
  const NarrativeStudioProductShell({
    super.key,
    required this.selectedDestination,
    required this.onSelectDestination,
    required this.onOpenMaps,
    required this.workspace,
    this.selectedLocation,
    this.onSelectLocation,
    this.onReturn,
    this.project,
    this.status,
    this.appMark,
  });

  final NarrativeStudioDestination selectedDestination;
  final ValueChanged<NarrativeStudioDestination> onSelectDestination;
  final VoidCallback onOpenMaps;
  final NarrativeStudioRouteLocation? selectedLocation;
  final ValueChanged<NarrativeStudioRouteLocation>? onSelectLocation;
  final VoidCallback? onReturn;
  final Widget workspace;
  final Widget? project;
  final Widget? status;
  final Widget? appMark;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final l10n = context.pokeMapL10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        final rail = narrativeStudioRailPresentation(constraints.maxWidth);
        return Semantics(
          key: narrativeStudioProductShellKey,
          container: true,
          label: l10n.shellSemantics,
          child: ColoredBox(
            color: colors.chromeBackground,
            child: Column(
              children: [
                _NarrativeStudioProductHeader(appMark: appMark),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: rail.width,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (project != null)
                              SizedBox(
                                key: narrativeStudioProductShellProjectKey,
                                height: 52,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(8, 8, 0, 8),
                                  child: project,
                                ),
                              ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
                                child: NarrativeStudioProductNavigation(
                                  key: narrativeStudioProductShellNavigationKey,
                                  selectedDestination: selectedDestination,
                                  selectedLocation: selectedLocation,
                                  onSelectDestination: onSelectDestination,
                                  onSelectLocation: onSelectLocation,
                                  onReturn: onReturn,
                                  onOpenMaps: onOpenMaps,
                                  status: status,
                                  collapsed: rail.collapsed,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8, bottom: 8),
                          child: SizedBox.expand(
                            key: narrativeStudioProductShellWorkspaceKey,
                            child: workspace,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NarrativeStudioProductHeader extends StatelessWidget {
  const _NarrativeStudioProductHeader({required this.appMark});

  final Widget? appMark;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final l10n = context.pokeMapL10n;
    return SizedBox(
      key: narrativeStudioProductShellHeaderKey,
      height: 50,
      child: PokeMapToolbarSurface(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Semantics(
              image: true,
              label: l10n.brandName,
              child: ExcludeSemantics(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: appMark ??
                      Image.asset(
                        'assets/branding/pokemap_event_builder_mark.png',
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.medium,
                      ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              l10n.brandName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 10),
            PokeMapBadge(
              label: l10n.beta,
              variant: PokeMapBadgeVariant.info,
            ),
          ],
        ),
      ),
    );
  }
}
