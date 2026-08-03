import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../../ui/design_system/design_system.dart';

final class SmartTileMaterialPickerItem {
  const SmartTileMaterialPickerItem({
    required this.material,
    required this.isFromProject,
    required this.isAllowed,
    this.removalBlockedReason,
  });

  final ProjectSmartTileMaterial material;
  final bool isFromProject;
  final bool isAllowed;
  final String? removalBlockedReason;
}

class SmartTileMaterialPicker extends StatelessWidget {
  const SmartTileMaterialPicker({
    super.key,
    required this.items,
    required this.defaultMaterialId,
    required this.activeMaterialId,
    required this.onActivate,
    required this.onSetDefault,
    required this.onToggleAllowed,
  });

  final List<SmartTileMaterialPickerItem> items;
  final String defaultMaterialId;
  final String activeMaterialId;
  final ValueChanged<ProjectSmartTileMaterial> onActivate;
  final ValueChanged<String> onSetDefault;
  final ValueChanged<String> onToggleAllowed;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const PokeMapEmptyState(
        title: 'Aucune matière disponible',
        description: 'Créez la première matière de ce Smart Tile.',
        icon: Icon(CupertinoIcons.paintbrush),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final item in items) ...[
          PokeMapAssetCard(
            key: Key('smart-tiles-material-${item.material.id}'),
            thumbnail: const Icon(CupertinoIcons.paintbrush, size: 20),
            label: item.material.name,
            description: item.isFromProject
                ? 'Matière déjà enregistrée dans le projet'
                : 'Matière privée de ce brouillon',
            selected: activeMaterialId == item.material.id,
            onPressed: () => onActivate(item.material),
            trailing: Wrap(
              spacing: 5,
              runSpacing: 5,
              children: <Widget>[
                if (defaultMaterialId == item.material.id)
                  const PokeMapBadge(
                    label: 'Par défaut',
                    variant: PokeMapBadgeVariant.success,
                  )
                else if (item.isAllowed)
                  PokeMapButton(
                    key: Key(
                      'smart-tiles-material-default-${item.material.id}',
                    ),
                    onPressed: () => onSetDefault(item.material.id),
                    size: PokeMapButtonSize.small,
                    variant: PokeMapButtonVariant.ghost,
                    child: const Text('Définir par défaut'),
                  ),
                PokeMapButton(
                  key: Key(
                    'smart-tiles-material-toggle-${item.material.id}',
                  ),
                  onPressed: item.removalBlockedReason == null
                      ? () => onToggleAllowed(item.material.id)
                      : null,
                  disabledReason: item.removalBlockedReason,
                  size: PokeMapButtonSize.small,
                  variant: PokeMapButtonVariant.ghost,
                  child: Text(item.isAllowed ? 'Retirer' : 'Ajouter'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
