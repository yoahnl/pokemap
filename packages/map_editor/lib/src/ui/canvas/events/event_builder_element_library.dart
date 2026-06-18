import 'package:flutter/cupertino.dart';

import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

enum EventBuilderLibraryAction {
  triggerActor,
  triggerObject,
  triggerZone,
  conditionFact,
  conditionEventConsumed,
  actionScene,
}

class EventBuilderElementLibrary extends StatefulWidget {
  const EventBuilderElementLibrary({
    super.key,
    this.onActivate,
  });

  final void Function(EventBuilderLibraryAction action)? onActivate;

  @override
  State<EventBuilderElementLibrary> createState() =>
      _EventBuilderElementLibraryState();
}

class _EventBuilderElementLibraryState
    extends State<EventBuilderElementLibrary> {
  String? _feedback;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final groups = _libraryGroups();
    return PokeMapPanel(
      key: const ValueKey('event-builder-element-library'),
      expandChild: true,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bibliothèque d’éléments',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cliquez pour ouvrir le bloc compatible dans le builder.',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          if (_feedback != null) ...[
            const SizedBox(height: 8),
            PokeMapBadge(
              key: const ValueKey('event-builder-library-feedback'),
              label: _feedback!,
              variant: PokeMapBadgeVariant.warning,
            ),
          ],
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: groups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final group = groups[index];
                return _ElementLibraryGroupCard(
                  group: group,
                  onActivate: _activateItem,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _activateItem(_ElementLibraryItem item) {
    if (!item.available || item.action == null) {
      setState(() {
        _feedback = 'Cet élément arrive dans un prochain lot.';
      });
      return;
    }
    widget.onActivate?.call(item.action!);
    setState(() {
      _feedback = 'Bloc ouvert dans le builder.';
    });
  }
}

class _ElementLibraryGroupCard extends StatelessWidget {
  const _ElementLibraryGroupCard({
    required this.group,
    required this.onActivate,
  });

  final _ElementLibraryGroup group;
  final void Function(_ElementLibraryItem item) onActivate;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final toneColors = group.tone.resolve(context);
    return PokeMapCard(
      key: ValueKey('event-builder-library-group-${group.id}'),
      borderRadius: 8,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(group.icon, size: 15, color: toneColors.icon),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  group.title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final item in group.items) ...[
            _ElementLibraryItemCard(
              item: item,
              onActivate: () => onActivate(item),
            ),
            if (item != group.items.last) const SizedBox(height: 5),
          ],
        ],
      ),
    );
  }
}

class _ElementLibraryItemCard extends StatelessWidget {
  const _ElementLibraryItemCard({
    required this.item,
    required this.onActivate,
  });

  final _ElementLibraryItem item;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    final toneColors = item.tone.resolve(context);
    return PokeMapButton(
      key: ValueKey('event-builder-library-item-${item.id}'),
      onPressed: onActivate,
      variant: item.available
          ? PokeMapButtonVariant.secondary
          : PokeMapButtonVariant.ghost,
      size: PokeMapButtonSize.small,
      leading: Icon(item.icon, color: toneColors.icon),
      trailing: PokeMapBadge(
        label: item.available ? 'Disponible' : 'À venir',
        variant: item.available
            ? PokeMapBadgeVariant.success
            : PokeMapBadgeVariant.neutral,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(item.label),
      ),
    );
  }
}

class _ElementLibraryGroup {
  const _ElementLibraryGroup({
    required this.id,
    required this.title,
    required this.icon,
    required this.tone,
    required this.items,
  });

  final String id;
  final String title;
  final IconData icon;
  final PokeMapTone tone;
  final List<_ElementLibraryItem> items;
}

class _ElementLibraryItem {
  const _ElementLibraryItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.tone,
    required this.available,
    this.action,
  });

  final String id;
  final String label;
  final IconData icon;
  final PokeMapTone tone;
  final bool available;
  final EventBuilderLibraryAction? action;
}

List<_ElementLibraryGroup> _libraryGroups() {
  return const [
    _ElementLibraryGroup(
      id: 'triggers',
      title: 'Déclencheurs',
      icon: CupertinoIcons.bolt_horizontal_circle,
      tone: PokeMapTone.quest,
      items: [
        _ElementLibraryItem(
          id: 'trigger-actor',
          label: 'Interaction PNJ',
          icon: CupertinoIcons.person_crop_circle,
          tone: PokeMapTone.quest,
          available: true,
          action: EventBuilderLibraryAction.triggerActor,
        ),
        _ElementLibraryItem(
          id: 'trigger-object',
          label: 'Interaction objet',
          icon: CupertinoIcons.cube_box,
          tone: PokeMapTone.quest,
          available: true,
          action: EventBuilderLibraryAction.triggerObject,
        ),
        _ElementLibraryItem(
          id: 'trigger-zone',
          label: 'Entrée dans une zone',
          icon: CupertinoIcons.square_grid_2x2,
          tone: PokeMapTone.quest,
          available: true,
          action: EventBuilderLibraryAction.triggerZone,
        ),
      ],
    ),
    _ElementLibraryGroup(
      id: 'conditions',
      title: 'Conditions',
      icon: CupertinoIcons.slider_horizontal_3,
      tone: PokeMapTone.info,
      items: [
        _ElementLibraryItem(
          id: 'condition-fact',
          label: 'Fact vrai / faux',
          icon: CupertinoIcons.checkmark_shield,
          tone: PokeMapTone.fact,
          available: true,
          action: EventBuilderLibraryAction.conditionFact,
        ),
        _ElementLibraryItem(
          id: 'condition-event-consumed',
          label: 'Événement consommé',
          icon: CupertinoIcons.flag,
          tone: PokeMapTone.info,
          available: true,
          action: EventBuilderLibraryAction.conditionEventConsumed,
        ),
        _ElementLibraryItem(
          id: 'condition-story-step',
          label: 'Étape narrative',
          icon: CupertinoIcons.list_bullet,
          tone: PokeMapTone.narrative,
          available: false,
        ),
      ],
    ),
    _ElementLibraryGroup(
      id: 'actions',
      title: 'Actions',
      icon: CupertinoIcons.play_rectangle,
      tone: PokeMapTone.success,
      items: [
        _ElementLibraryItem(
          id: 'action-scene',
          label: 'Jouer une scène',
          icon: CupertinoIcons.play_rectangle,
          tone: PokeMapTone.success,
          available: true,
          action: EventBuilderLibraryAction.actionScene,
        ),
        _ElementLibraryItem(
          id: 'action-battle',
          label: 'Combat',
          icon: CupertinoIcons.shield,
          tone: PokeMapTone.danger,
          available: false,
        ),
      ],
    ),
    _ElementLibraryGroup(
      id: 'results',
      title: 'Résultats',
      icon: CupertinoIcons.flag_circle,
      tone: PokeMapTone.brand,
      items: [
        _ElementLibraryItem(
          id: 'result-victory',
          label: 'Victoire',
          icon: CupertinoIcons.rosette,
          tone: PokeMapTone.success,
          available: false,
        ),
      ],
    ),
    _ElementLibraryGroup(
      id: 'reactions',
      title: 'Réactions',
      icon: CupertinoIcons.arrow_turn_down_right,
      tone: PokeMapTone.warning,
      items: [
        _ElementLibraryItem(
          id: 'reaction-set-fact',
          label: 'Définir un Fact',
          icon: CupertinoIcons.checkmark_alt_circle,
          tone: PokeMapTone.fact,
          available: false,
        ),
      ],
    ),
    _ElementLibraryGroup(
      id: 'world',
      title: 'Monde',
      icon: CupertinoIcons.globe,
      tone: PokeMapTone.fact,
      items: [
        _ElementLibraryItem(
          id: 'world-enable-element',
          label: 'Activer élément',
          icon: CupertinoIcons.eye,
          tone: PokeMapTone.map,
          available: false,
        ),
      ],
    ),
  ];
}
