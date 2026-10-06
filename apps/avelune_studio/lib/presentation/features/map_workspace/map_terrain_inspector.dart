import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../shared/widgets/layout/studio_sidebar.dart';
import '../resources/resource_catalog.dart';
import '../resources/resource_preview.dart';
import 'map_workspace_view_state.dart';
import 'map_workspace_visuals.dart';

class MapTerrainInspector extends StatelessWidget {
  const MapTerrainInspector({
    super.key,
    required this.document,
    required this.project,
    required this.view,
    required this.visuals,
    required this.onChanged,
    required this.width,
  });
  final EditableMapDocument document;
  final ProjectManifest project;
  final MapWorkspaceViewState view;
  final MapWorkspaceVisuals visuals;
  final VoidCallback onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    final preset = view.terrain;
    final item = resourceCatalog(project)
        .where(
          (item) => item.kind == ResourceKind.terrains && item.id == preset?.id,
        )
        .firstOrNull;
    return StudioSidebar(
      width: width,
      child: ListView(
        children: [
          Text(
            preset?.name ?? 'Édition du terrain',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (item != null)
            Align(
              alignment: Alignment.centerLeft,
              child: resourcePreview(item, project, visuals, size: 120),
            ),
          const SizedBox(height: 12),
          const Text(
            'Les cases peintes du terrain actif sont mises en évidence. Les textures restent visibles.',
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Mettre en évidence'),
            value: view.highlightTerrain,
            onChanged: (value) {
              view.highlightTerrain = value ?? false;
              onChanged();
            },
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Atténuer le reste de la carte'),
            value: view.dimOtherTerrains,
            onChanged: (value) {
              view.dimOtherTerrains = value ?? false;
              onChanged();
            },
          ),
          const Divider(height: 28),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.brush_outlined),
            title: Text('Cliquez ou glissez pour peindre.'),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.cleaning_services_outlined),
            title: Text('La gomme retire le terrain visible sous le pointeur.'),
            subtitle: Text('Son aperçu montre les cases qui seront retirées.'),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.open_with),
            title: Text('Espace + glisser pour déplacer la vue.'),
          ),
          if (preset != null)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Informations du terrain'),
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Raccords'),
                  subtitle: Text(
                    '${preset.rules.length} règles définies dans Ressources.',
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
