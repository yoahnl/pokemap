import 'package:flutter/cupertino.dart';

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
  });

  final NarrativeStudioDestination selectedDestination;
  final ValueChanged<NarrativeStudioDestination> onSelectDestination;
  final VoidCallback onOpenMaps;
  final NarrativeStudioRouteLocation? selectedLocation;
  final ValueChanged<NarrativeStudioRouteLocation>? onSelectLocation;
  final VoidCallback? onReturn;

  /// Real project status supplied by the host. No placeholder is rendered when
  /// it is absent.
  final Widget? status;

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      expandChild: true,
      padding: const EdgeInsets.all(8),
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Column(
          children: [
            if (onReturn != null) ...[
              _NarrativeStudioNavigationItem(
                key: const ValueKey<String>(
                  'narrative-studio-product-nav-return',
                ),
                icon: CupertinoIcons.arrow_left,
                label: 'Retour',
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
                label: item.label,
                selected: item.destination == selectedDestination,
                onTap: () => _selectDestination(item.destination),
              ),
              const SizedBox(height: 4),
            ],
            _NarrativeStudioNavigationItem(
              key: narrativeStudioProductNavigationMapsKey,
              icon: CupertinoIcons.map,
              label: 'Maps',
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
                label: item.label,
                selected: item.destination == selectedDestination,
                onTap: () => _selectDestination(item.destination),
              ),
              const SizedBox(height: 4),
              if (item.destination == NarrativeStudioDestination.events &&
                  selectedDestination == NarrativeStudioDestination.events)
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 4),
                  child: Column(
                    children: [
                      _NarrativeStudioNavigationItem(
                        key: narrativeStudioEventBuilderNavigationKey,
                        icon: CupertinoIcons.bolt_horizontal,
                        label: 'Event Builder',
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
                        label: 'Events par map',
                        selected: selectedLocation?.childRoute ==
                            NarrativeStudioChildRoute.mapEvents,
                        onTap: () => _selectLocation(
                          NarrativeStudioRouteLocation.events(
                            childRoute: NarrativeStudioChildRoute.mapEvents,
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
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PokeMapSidebarItem(
      icon: Icon(icon),
      label: label,
      compact: true,
      selected: selected,
      onTap: onTap,
    );
  }
}

class _DestinationNavigationItem {
  const _DestinationNavigationItem({
    required this.destination,
    required this.icon,
    required this.label,
  });

  final NarrativeStudioDestination destination;
  final IconData icon;
  final String label;
}

const _items = <_DestinationNavigationItem>[
  _DestinationNavigationItem(
    destination: NarrativeStudioDestination.overview,
    icon: CupertinoIcons.house,
    label: 'Aperçu',
  ),
  _DestinationNavigationItem(
    destination: NarrativeStudioDestination.storylines,
    icon: CupertinoIcons.rectangle_grid_1x2,
    label: 'Storylines',
  ),
  _DestinationNavigationItem(
    destination: NarrativeStudioDestination.scenes,
    icon: CupertinoIcons.photo,
    label: 'Scènes',
  ),
  _DestinationNavigationItem(
    destination: NarrativeStudioDestination.events,
    icon: CupertinoIcons.bolt_horizontal_circle,
    label: 'Événements',
  ),
  _DestinationNavigationItem(
    destination: NarrativeStudioDestination.cinematics,
    icon: CupertinoIcons.film,
    label: 'Cinématiques',
  ),
  _DestinationNavigationItem(
    destination: NarrativeStudioDestination.dialogues,
    icon: CupertinoIcons.text_bubble,
    label: 'Dialogues',
  ),
  _DestinationNavigationItem(
    destination: NarrativeStudioDestination.facts,
    icon: CupertinoIcons.doc_text,
    label: 'Facts',
  ),
  _DestinationNavigationItem(
    destination: NarrativeStudioDestination.worldRules,
    icon: CupertinoIcons.checkmark_shield,
    label: 'Règles du monde',
  ),
  _DestinationNavigationItem(
    destination: NarrativeStudioDestination.validator,
    icon: CupertinoIcons.checkmark_shield,
    label: 'Validateur',
  ),
];
