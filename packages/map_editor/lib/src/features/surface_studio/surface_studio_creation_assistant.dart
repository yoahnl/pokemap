import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';

const Color _accent = Color(0xFF2DD4BF);

/// Assistant de création purement visuel.
///
/// Les étapes reflètent l’état du catalogue Surface Studio sans créer de
/// raccourci métier : l’atlas, les animations et les surfaces peignables sont
/// toujours produits par les widgets auteur existants.
class SurfaceStudioCreationAssistant extends StatelessWidget {
  const SurfaceStudioCreationAssistant({
    super.key,
    required this.readModel,
  });

  final SurfaceStudioReadModel readModel;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final summary = readModel.summary;
    final items = _itemsFor(summary);

    return Container(
      key: const ValueKey('surface_studio_creation_assistant'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EditorChrome.editorIslandRim(context)),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Assistant de création',
            style: TextStyle(
              color: label,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Suivez ces étapes pour transformer votre atlas en surfaces peintes.',
            style: TextStyle(
              color: subtle,
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          for (final item in items) ...[
            _ChecklistRow(item: item),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 4),
          _CountPill(label: 'Atlas', value: summary.atlasCount),
          const SizedBox(height: 6),
          _CountPill(label: 'Animations', value: summary.animationCount),
          const SizedBox(height: 6),
          _CountPill(label: 'Surfaces', value: summary.presetCount),
          const SizedBox(height: 12),
          Container(
            key: const ValueKey('surface_studio_help_card'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: EditorChrome.islandFillElevated(context)
                  .withValues(alpha: 0.66),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _accent.withValues(alpha: 0.28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ce que vous faites ici',
                  style: TextStyle(
                    color: label,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Un atlas contient les images.\n'
                  'Les animations regroupent les frames.\n'
                  'Les surfaces sont les éléments finaux que vous pourrez peindre dans la map.',
                  style: TextStyle(
                    color: subtle.withValues(alpha: 0.95),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

List<_AssistantItem> _itemsFor(SurfaceStudioCatalogSummaryReadModel summary) {
  final hasAtlas = summary.atlasCount > 0;
  final hasAnimations = summary.animationCount > 0;
  final hasSurfaces = summary.presetCount > 0;

  return [
    _AssistantItem('Choisir une image atlas', hasAtlas, !hasAtlas),
    _AssistantItem(
        'Vérifier la taille des tuiles', hasAtlas, hasAtlas && !hasAnimations),
    _AssistantItem(
        'Confirmer colonnes et lignes', hasAtlas, hasAtlas && !hasAnimations),
    _AssistantItem(
        'Générer les animations', hasAnimations, hasAtlas && !hasAnimations),
    _AssistantItem('Créer les surfaces à peindre', hasSurfaces,
        hasAnimations && !hasSurfaces),
  ];
}

final class _AssistantItem {
  const _AssistantItem(this.label, this.done, this.active);

  final String label;
  final bool done;
  final bool active;
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.item});

  final _AssistantItem item;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final color = item.done || item.active ? _accent : subtle;
    final marker = item.done ? '✓' : (item.active ? '•' : '○');
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.14),
            border: Border.all(color: color.withValues(alpha: 0.75)),
          ),
          child: Text(
            marker,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            item.label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: item.active ? FontWeight.w800 : FontWeight.w600,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final text = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context).withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              color: text,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
