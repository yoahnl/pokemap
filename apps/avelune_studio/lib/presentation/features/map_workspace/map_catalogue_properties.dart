import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../shared/widgets/buttons/studio_button.dart';

class MapCatalogueProperties extends StatelessWidget {
  const MapCatalogueProperties({super.key, required this.map, this.onRename});
  final MapData map;
  final VoidCallback? onRename;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 8),
      Text('${map.size.width} × ${map.size.height} cases'),
      if (onRename != null) ...[
        const SizedBox(height: 8),
        StudioButton(
          label: 'Renommer la carte…',
          secondary: true,
          icon: Icons.edit_outlined,
          onPressed: onRename,
        ),
      ],
      const SizedBox(height: 20),
    ],
  );
}
