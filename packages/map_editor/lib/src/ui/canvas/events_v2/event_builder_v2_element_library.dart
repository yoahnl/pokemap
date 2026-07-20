import 'package:flutter/cupertino.dart';

import '../../design_system/design_system.dart';

class EventBuilderV2ElementLibrary extends StatelessWidget {
  const EventBuilderV2ElementLibrary({
    super.key,
    required this.hasLinkedScene,
    this.onOpenScene,
    this.onCreateTemplate,
    this.hasPendingTemplate = false,
  });

  final bool hasLinkedScene;
  final VoidCallback? onOpenScene;
  final VoidCallback? onCreateTemplate;
  final bool hasPendingTemplate;

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      borderRadius: 8,
      expandChild: true,
      padding: EdgeInsets.zero,
      header: const Padding(
        padding: EdgeInsets.fromLTRB(10, 10, 10, 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bibliothèque d’éléments',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 2),
            Text(
              'Repères de la configuration.',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      child: ListView(
        key: const ValueKey('event-builder-v2-library-scroll'),
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
        children: [
          const _LibraryGroup(
            title: 'Déclencheurs',
            tone: PokeMapTone.narrative,
            items: [
              _LibraryItem(
                'Interaction avec un PNJ',
                CupertinoIcons.bolt_fill,
                PokeMapTone.narrative,
              ),
              _LibraryItem(
                'Entrée dans une zone',
                CupertinoIcons.map_pin_ellipse,
                PokeMapTone.narrative,
              ),
              _LibraryItem(
                'Interaction avec un objet',
                CupertinoIcons.cube_box_fill,
                PokeMapTone.narrative,
              ),
              _LibraryItem(
                'Entrée sur une map',
                CupertinoIcons.map_fill,
                PokeMapTone.narrative,
              ),
            ],
            keyPrefix: 'event-builder-v2-library-authorable',
          ),
          const SizedBox(height: 6),
          const _LibraryGroup(
            title: 'Conditions',
            tone: PokeMapTone.info,
            items: [
              _LibraryItem(
                'Fact du projet',
                CupertinoIcons.checkmark_alt_circle_fill,
                PokeMapTone.info,
              ),
              _LibraryItem(
                'Événement consommé',
                CupertinoIcons.link,
                PokeMapTone.info,
              ),
            ],
            keyPrefix: 'event-builder-v2-library-conditions',
          ),
          const SizedBox(height: 6),
          const _LibraryGroup(
            title: 'Scene liée',
            tone: PokeMapTone.success,
            readOnly: true,
            items: [
              _LibraryItem(
                'Orchestration de la Scene',
                CupertinoIcons.play_rectangle_fill,
                PokeMapTone.success,
              ),
            ],
            keyPrefix: 'event-builder-v2-library-scene',
          ),
          const SizedBox(height: 6),
          const _LibraryGroup(
            title: 'Résultats',
            tone: PokeMapTone.narrative,
            readOnly: true,
            items: [
              _LibraryItem(
                'Victoire',
                CupertinoIcons.flag_fill,
                PokeMapTone.narrative,
              ),
              _LibraryItem(
                'Défaite',
                CupertinoIcons.flag_fill,
                PokeMapTone.narrative,
              ),
              _LibraryItem(
                'Échec',
                CupertinoIcons.flag_fill,
                PokeMapTone.narrative,
              ),
            ],
            keyPrefix: 'event-builder-v2-library-scene-results',
          ),
          const SizedBox(height: 6),
          const _LibraryGroup(
            title: 'Réactions',
            tone: PokeMapTone.warning,
            readOnly: true,
            items: [
              _LibraryItem(
                'Définir un Fact',
                CupertinoIcons.bolt_circle_fill,
                PokeMapTone.warning,
              ),
              _LibraryItem(
                'Terminer une étape',
                CupertinoIcons.checkmark_seal_fill,
                PokeMapTone.warning,
              ),
              _LibraryItem(
                'Combat et dialogue',
                CupertinoIcons.sparkles,
                PokeMapTone.warning,
              ),
            ],
            keyPrefix: 'event-builder-v2-library-scene-reactions',
          ),
          const SizedBox(height: 6),
          const _LibraryGroup(
            title: 'Monde',
            tone: PokeMapTone.map,
            readOnly: true,
            items: [
              _LibraryItem(
                'Règles du monde projetées',
                CupertinoIcons.globe,
                PokeMapTone.map,
              ),
            ],
            keyPrefix: 'event-builder-v2-library-scene-world',
          ),
          if (onCreateTemplate != null || hasPendingTemplate) ...[
            const SizedBox(height: 9),
            PokeMapButton(
              key: const ValueKey('event-builder-v2-template-entry'),
              onPressed: onCreateTemplate,
              variant: PokeMapButtonVariant.secondary,
              size: PokeMapButtonSize.small,
              leading: const Icon(CupertinoIcons.sparkles),
              child: Text(
                hasPendingTemplate
                    ? 'Reprendre le gabarit'
                    : 'Créer un gabarit',
              ),
            ),
            const SizedBox(height: 6),
          ] else
            const SizedBox(height: 9),
          if (hasLinkedScene && onOpenScene != null)
            PokeMapButton(
              onPressed: onOpenScene,
              variant: PokeMapButtonVariant.ghost,
              size: PokeMapButtonSize.small,
              leading: const Icon(CupertinoIcons.arrow_up_right_square),
              child: const Text('Ouvrir la Scene'),
            )
          else if (!hasLinkedScene)
            const PokeMapBadge(
              label: 'Liez une Scene pour voir ses projections',
              variant: PokeMapBadgeVariant.neutral,
              icon: Icon(CupertinoIcons.info_circle),
            )
          else
            const PokeMapBadge(
              label: 'Scene liée — ouverture indisponible',
              variant: PokeMapBadgeVariant.neutral,
              icon: Icon(CupertinoIcons.info_circle),
            ),
        ],
      ),
    );
  }
}

class _LibraryGroup extends StatelessWidget {
  const _LibraryGroup({
    this.title,
    required this.tone,
    required this.items,
    required this.keyPrefix,
    this.readOnly = false,
  });

  final String? title;
  final PokeMapTone tone;
  final List<_LibraryItem> items;
  final String keyPrefix;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final toneColors = tone.resolve(context);
    return PokeMapCard(
      borderRadius: 7,
      backgroundColor: toneColors.soft,
      padding: const EdgeInsets.fromLTRB(6, 5, 6, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Icon(
                  readOnly
                      ? CupertinoIcons.lock
                      : CupertinoIcons.slider_horizontal_3,
                  size: 10,
                  color: toneColors.icon,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    title!.toUpperCase(),
                    style: TextStyle(
                      color: toneColors.text,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
          for (var index = 0; index < items.length; index++) ...[
            _LibraryRow(
              key: ValueKey('$keyPrefix-$index'),
              item: items[index],
              readOnly: readOnly,
            ),
            if (index < items.length - 1) const SizedBox(height: 3),
          ],
        ],
      ),
    );
  }
}

class _LibraryRow extends StatelessWidget {
  const _LibraryRow({super.key, required this.item, required this.readOnly});

  final _LibraryItem item;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final toneColors = item.tone.resolve(context);
    return Semantics(
      container: true,
      label: readOnly
          ? '${item.label}, défini dans la Scene, lecture seule'
          : '${item.label}, configurable dans l’événement',
      child: PokeMapCard(
        borderRadius: 5,
        backgroundColor: toneColors.soft,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          children: [
            Icon(item.icon, size: 12, color: toneColors.icon),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (readOnly)
                    const Text(
                      'Défini dans la Scene',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            if (readOnly) ...[
              const SizedBox(width: 3),
              const Icon(CupertinoIcons.lock, size: 9),
            ],
          ],
        ),
      ),
    );
  }
}

class _LibraryItem {
  const _LibraryItem(this.label, this.icon, this.tone);

  final String label;
  final IconData icon;
  final PokeMapTone tone;
}
