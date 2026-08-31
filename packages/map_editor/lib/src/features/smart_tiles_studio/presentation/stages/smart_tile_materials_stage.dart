import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../../ui/design_system/design_system.dart';
import 'smart_tile_material_picker.dart';

class SmartTileMaterialsStage extends StatelessWidget {
  const SmartTileMaterialsStage({
    super.key,
    required this.usage,
    required this.items,
    required this.defaultMaterialId,
    required this.activeMaterialId,
    required this.newMaterialNameController,
    required this.canCreateMaterial,
    required this.canContinue,
    required this.onActivate,
    required this.onSetDefault,
    required this.onToggleAllowed,
    required this.onNewMaterialNameChanged,
    required this.onCreateMaterial,
    required this.onContinue,
  });

  final SmartTileUsage usage;

  final List<SmartTileMaterialPickerItem> items;
  final String defaultMaterialId;
  final String activeMaterialId;
  final TextEditingController newMaterialNameController;
  final bool canCreateMaterial;
  final bool canContinue;
  final ValueChanged<ProjectSmartTileMaterial> onActivate;
  final ValueChanged<String> onSetDefault;
  final ValueChanged<String> onToggleAllowed;
  final ValueChanged<String> onNewMaterialNameChanged;
  final VoidCallback onCreateMaterial;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[ PokeMapSectionHeader(
          title: usage == SmartTileUsage.path
              ? 'Nommer ce que vous allez peindre'
              : 'Choisir la peinture de ce Smart Tile',
          description: usage == SmartTileUsage.path
              ? 'Pour un chemin simple, une seule peinture suffit. PokeMap en a déjà préparé une ; vous pouvez continuer directement.'
              : 'La peinture active est celle que vous placerez sur la carte. Les choix supplémentaires restent facultatifs.',
        ),
        if (usage == SmartTileUsage.path) ...[
          const SizedBox(height: 10),
          const PokeMapPanel(
            key: Key('smart-tiles-simple-path-material-ready'),
            padding: EdgeInsets.all(12),
            child: PokeMapSectionHeader(
              title: 'Votre chemin est prêt à être peint',
              description:
                  'Gardez cette peinture unique, sauf si le même atlas contient réellement plusieurs types de chemin.',
            ),
          ),
        ],
        const SizedBox(height: 12),
        SmartTileMaterialPicker(
          items: items,
          defaultMaterialId: defaultMaterialId,
          activeMaterialId: activeMaterialId,
          onActivate: onActivate,
          onSetDefault: onSetDefault,
          onToggleAllowed: onToggleAllowed,
        ),
        const SizedBox(height: 12),
        PokeMapPanel(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: PokeMapTextField(
                  label: 'Nouvelle matière',
                  controller: newMaterialNameController,
                  fieldKey: const Key('smart-tiles-new-material-name'),
                  hintText: 'Ex. Herbe fraîche',
                  onChanged: onNewMaterialNameChanged,
                  onSubmitted: (_) {
                    if (canCreateMaterial) onCreateMaterial();
                  },
                ),
              ),
              const SizedBox(width: 8),
              PokeMapButton(
                key: const Key('smart-tiles-create-material'),
                onPressed: canCreateMaterial ? onCreateMaterial : null,
                leading: const Icon(CupertinoIcons.add, size: 14),
                child: const Text('Créer'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: PokeMapButton(
            key: const Key('smart-tiles-materials-next-step'),
            onPressed: canContinue ? onContinue : null,
            trailing: const Icon(CupertinoIcons.chevron_right, size: 14),
            child: Text(
              usage == SmartTileUsage.path
                  ? 'Choisir la forme du chemin'
                  : 'Choisir le tracé automatique',),
          ),
        ),
      ],
    );
  }
}
