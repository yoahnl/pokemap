import 'package:flutter/cupertino.dart';

import '../../../../l10n/l10n.dart';
import '../../design_system/design_system.dart';
import 'narrative_studio_destination.dart';

const narrativeStudioProductNavigationMapsKey =
    ValueKey<String>('narrative-studio-product-nav-maps');
const narrativeStudioProductNavigationStatusKey =
    ValueKey<String>('narrative-studio-product-navigation-status');
const narrativeStudioEventBuilderNavigationKey =
    ValueKey<String>('narrative-studio-product-nav-event-builder');
const narrativeStudioMapEventsNavigationKey =
    ValueKey<String>('narrative-studio-product-nav-map-events');
const narrativeStudioProductNavigationScrollKey =
    ValueKey<String>('narrative-studio-product-navigation-scroll');

/// Provider-free project navigation shared by Narrative Studio workspaces.
class NarrativeStudioProductNavigation extends StatelessWidget {
  const NarrativeStudioProductNavigation({
    super.key,
    required this.selectedDestination,
    required this.onSelectDestination,
    required this.onOpenMaps,
    this.selectedLocation,
    this.onSelectLocation,
    this.onReturn,
    this.status,
    this.collapsed = false,
  });

  final NarrativeStudioDestination selectedDestination;
  final ValueChanged<NarrativeStudioDestination> onSelectDestination;
  final VoidCallback onOpenMaps;
  final NarrativeStudioRouteLocation? selectedLocation;
  final ValueChanged<NarrativeStudioRouteLocation>? onSelectLocation;
  final VoidCallback? onReturn;

  /// Uses icon-only rows while retaining localized tooltip and semantics.
  final bool collapsed;

  /// Real project status supplied by the host. No placeholder is rendered when
  /// it is absent.
  final Widget? status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.pokeMapL10n;
    return PokeMapPanel(
      expandChild: true,
      padding: const EdgeInsets.all(8),
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            key: narrativeStudioProductNavigationScrollKey,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    if (onReturn != null) ...[
                      _NarrativeStudioNavigationItem(
                        key: const ValueKey<String>(
                          'narrative-studio-product-nav-return',
                        ),
                        icon: CupertinoIcons.arrow_left,
                        label: l10n.back,
                        collapsed: collapsed,
                        selected: false,
                        onTap: onReturn!,
                      ),
                      const SizedBox(height: 8),
                    ],
                    for (final item in _items.take(2)) ...[
                      _NarrativeStudioNavigationItem(
                        key: ValueKey<String>(
                          'narrative-studio-product-nav-${item.destination.name}',
                        ),
                        icon: item.icon,
                        label: _destinationLabel(context, item.destination),
                        collapsed: collapsed,
                        selected: item.destination == selectedDestination,
                        onTap: () => _selectDestination(item.destination),
                      ),
                      const SizedBox(height: 4),
                    ],
                    _NarrativeStudioNavigationItem(
                      key: narrativeStudioProductNavigationMapsKey,
                      icon: CupertinoIcons.map,
                      label: l10n.maps,
                      collapsed: collapsed,
                      selected: false,
                      onTap: onOpenMaps,
                    ),
                    const SizedBox(height: 4),
                    for (final item in _items.skip(2)) ...[
                      _NarrativeStudioNavigationItem(
                        key: ValueKey<String>(
                          'narrative-studio-product-nav-${item.destination.name}',
                        ),
                        icon: item.icon,
                        label: _destinationLabel(context, item.destination),
                        collapsed: collapsed,
                        selected: item.destination == selectedDestination,
                        onTap: () => _selectDestination(item.destination),
                      ),
                      const SizedBox(height: 4),
                      if (item.destination ==
                              NarrativeStudioDestination.events &&
                          selectedDestination ==
                              NarrativeStudioDestination.events)
                        Padding(
                          padding: EdgeInsets.only(
                            left: collapsed ? 0 : 12,
                            bottom: 4,
                          ),
                          child: Column(
                            children: [
                              _NarrativeStudioNavigationItem(
                                key: narrativeStudioEventBuilderNavigationKey,
                                icon: CupertinoIcons.bolt_horizontal,
                                label: l10n.eventBuilder,
                                collapsed: collapsed,
                                selected: selectedLocation?.childRoute !=
                                    NarrativeStudioChildRoute.mapEvents,
                                onTap: () => _selectLocation(
                                  NarrativeStudioRouteLocation.events(),
                                ),
                              ),
                              const SizedBox(height: 4),
                              _NarrativeStudioNavigationItem(
                                key: narrativeStudioMapEventsNavigationKey,
                                icon: CupertinoIcons.map_pin_ellipse,
                                label: l10n.mapEvents,
                                collapsed: collapsed,
                                selected: selectedLocation?.childRoute ==
                                    NarrativeStudioChildRoute.mapEvents,
                                onTap: () => _selectLocation(
                                  NarrativeStudioRouteLocation.events(
                                    childRoute:
                                        NarrativeStudioChildRoute.mapEvents,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    if (status != null) ...[
                      const Spacer(),
                      SizedBox(
                        key: narrativeStudioProductNavigationStatusKey,
                        width: double.infinity,
                        child: status,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _selectDestination(NarrativeStudioDestination destination) {
    final callback = onSelectLocation;
    if (callback == null) {
      onSelectDestination(destination);
      return;
    }
    callback(_defaultLocationFor(destination));
  }

  void _selectLocation(NarrativeStudioRouteLocation location) {
    final callback = onSelectLocation;
    if (callback == null) {
      onSelectDestination(location.destination);
      return;
    }
    callback(location);
  }
}

NarrativeStudioRouteLocation _defaultLocationFor(
  NarrativeStudioDestination destination,
) =>
    switch (destination) {
      NarrativeStudioDestination.overview =>
        NarrativeStudioRouteLocation.overview(),
      NarrativeStudioDestination.storylines =>
        NarrativeStudioRouteLocation.storylines(),
      NarrativeStudioDestination.scenes =>
        NarrativeStudioRouteLocation.scenes(),
      NarrativeStudioDestination.events =>
        NarrativeStudioRouteLocation.events(),
      NarrativeStudioDestination.cinematics =>
        NarrativeStudioRouteLocation.cinematics(),
      NarrativeStudioDestination.dialogues =>
        NarrativeStudioRouteLocation.dialogues(),
      NarrativeStudioDestination.facts => NarrativeStudioRouteLocation.facts(),
      NarrativeStudioDestination.worldRules =>
        NarrativeStudioRouteLocation.worldRules(),
      NarrativeStudioDestination.validator =>
        NarrativeStudioRouteLocation.validator(),
    };

class _NarrativeStudioNavigationItem extends StatelessWidget {
  const _NarrativeStudioNavigationItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.collapsed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return PokeMapSidebarItem(
      icon: Icon(icon),
      label: label,
      compact: true,
      collapsed: collapsed,
      selected: selected,
      onTap: onTap,
    );
  }
}

class _DestinationNavigationItem {
  const _DestinationNavigationItem({
    required this.destination,
    required this.icon,
  });

  final NarrativeStudioDestination destination;
  final IconData icon;
}

/// Keeps destination identity provider-free while the generated shell
/// localization remains the single owner of user-visible rail labels.
String _destinationLabel(
  BuildContext context,
  NarrativeStudioDestination destination,
) =>
    switch (destination) {
      NarrativeStudioDestination.overview => context.pokeMapL10n.overview,
      NarrativeStudioDestination.storylines => context.pokeMapL10n.storylines,
      NarrativeStudioDestination.scenes => context.pokeMapL10n.scenes,
      NarrativeStudioDestination.events => context.pokeMapL10n.events,
      NarrativeStudioDestination.cinematics => context.pokeMapL10n.cinematics,
      NarrativeStudioDestination.dialogues => context.pokeMapL10n.dialogues,
      NarrativeStudioDestination.facts => context.pokeMapL10n.facts,
      NarrativeStudioDestination.worldRules => context.pokeMapL10n.worldRules,
      NarrativeStudioDestination.validator => context.pokeMapL10n.validator,
    };

const _items = <_DestinationNavigationItem>[
  _DestinationNavigationItem(
    destination: NarrativeStudioDestination.overview,
    icon: CupertinoIcons.house,
  ),
  _DestinationNavigationItem(
    destination: NarrativeStudioDestination.storylines,
    icon: CupertinoIcons.rectangle_grid_1x2,
  ),
  _DestinationNavigationItem(
    destination: NarrativeStudioDestination.scenes,
    icon: CupertinoIcons.photo,
  ),
  _DestinationNavigationItem(
    destination: NarrativeStudioDestination.events,
    icon: CupertinoIcons.bolt_horizontal_circle,
  ),
  _DestinationNavigationItem(
    destination: NarrativeStudioDestination.cinematics,
    icon: CupertinoIcons.film,
  ),
  _DestinationNavigationItem(
    destination: NarrativeStudioDestination.dialogues,
    icon: CupertinoIcons.text_bubble,
  ),
  _DestinationNavigationItem(
    destination: NarrativeStudioDestination.facts,
    icon: CupertinoIcons.doc_text,
  ),
  _DestinationNavigationItem(
    destination: NarrativeStudioDestination.worldRules,
    icon: CupertinoIcons.checkmark_shield,
  ),
  _DestinationNavigationItem(
    destination: NarrativeStudioDestination.validator,
    icon: CupertinoIcons.checkmark_shield,
  ),
];
