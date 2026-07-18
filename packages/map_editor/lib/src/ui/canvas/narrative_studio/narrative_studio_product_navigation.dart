import 'package:flutter/cupertino.dart';

import '../../design_system/design_system.dart';
import 'narrative_studio_destination.dart';

const narrativeStudioProductNavigationMapsKey =
    ValueKey<String>('narrative-studio-product-nav-maps');
const narrativeStudioProductNavigationStatusKey =
    ValueKey<String>('narrative-studio-product-navigation-status');

/// Provider-free project navigation shared by Narrative Studio workspaces.
class NarrativeStudioProductNavigation extends StatelessWidget {
  const NarrativeStudioProductNavigation({
    super.key,
    required this.selectedDestination,
    required this.onSelectDestination,
    required this.onOpenMaps,
    this.status,
  });

  final NarrativeStudioDestination selectedDestination;
  final ValueChanged<NarrativeStudioDestination> onSelectDestination;
  final VoidCallback onOpenMaps;

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
            for (final item in _items.take(2)) ...[
              _NarrativeStudioNavigationItem(
                key: ValueKey<String>(
                  'narrative-studio-product-nav-${item.destination.name}',
                ),
                icon: item.icon,
                label: item.label,
                selected: item.destination == selectedDestination,
                onTap: () => onSelectDestination(item.destination),
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
                onTap: () => onSelectDestination(item.destination),
              ),
              const SizedBox(height: 4),
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
}

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
