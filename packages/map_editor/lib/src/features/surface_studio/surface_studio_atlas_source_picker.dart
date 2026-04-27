import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' as material;
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';

String suggestInternalAtlasIdFromName(String name) {
  var s = name.trim().toLowerCase();
  s = s.replaceAll(RegExp(r'[àáâäã]'), 'a');
  s = s.replaceAll(RegExp(r'[èéêë]'), 'e');
  s = s.replaceAll(RegExp(r'[ìíîï]'), 'i');
  s = s.replaceAll(RegExp(r'[òóôöõ]'), 'o');
  s = s.replaceAll(RegExp(r'[ùúûü]'), 'u');
  s = s.replaceAll('ç', 'c');
  s = s.replaceAll('œ', 'oe');
  s = s.replaceAll('æ', 'ae');
  s = s.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  s = s.replaceAll(RegExp(r'-+'), '-');
  s = s.replaceAll(RegExp(r'^-|-$'), '');
  if (s.isEmpty) {
    return 'atlas';
  }
  return s;
}

List<ProjectTilesetEntry> sortedTilesetChoices(
  List<ProjectTilesetEntry> t,
) {
  final o = List<ProjectTilesetEntry>.from(t);
  o.sort((a, b) {
    final c = a.sortOrder.compareTo(b.sortOrder);
    if (c != 0) {
      return c;
    }
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return o;
}

class SurfaceStudioAtlasImageSourceBlock extends StatelessWidget {
  const SurfaceStudioAtlasImageSourceBlock({
    super.key,
    required this.hasPicker,
    required this.sortedTilesets,
    required this.selectedTilesetId,
    required this.onSelectTilesetId,
    required this.label,
    required this.subtle,
  });

  final bool hasPicker;
  final List<ProjectTilesetEntry> sortedTilesets;
  final String? selectedTilesetId;
  final ValueChanged<String?> onSelectTilesetId;
  final Color label;
  final Color subtle;

  @override
  Widget build(BuildContext context) {
    return material.Material(
      type: material.MaterialType.transparency,
      child: Column(
        key: const ValueKey('surface_studio_atlas_image_source_section'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Image source de l’atlas',
            style: TextStyle(
              color: label,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          if (hasPicker) ...[
            material.DropdownButton<String?>(
              key: const ValueKey('surface_studio_atlas_tileset_picker'),
              isExpanded: true,
              value: _valueForDropdown,
              style: TextStyle(color: label, fontSize: 13),
              iconEnabledColor: label,
              iconDisabledColor: subtle,
              dropdownColor: EditorChrome.elevatedPanelBackground(context),
              hint: Text(
                'Choisir une image',
                style: TextStyle(color: subtle, fontSize: 13),
              ),
              items: [
                for (final e in sortedTilesets)
                  material.DropdownMenuItem<String?>(
                    value: e.id,
                    child: Text(
                      e.name,
                      style: TextStyle(color: label, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (selectedTilesetId != null &&
                    selectedTilesetId!.isNotEmpty &&
                    !sortedTilesets.any((e) => e.id == selectedTilesetId))
                  material.DropdownMenuItem<String?>(
                    value: selectedTilesetId,
                    child: Text(
                      'Référence actuelle · $selectedTilesetId',
                      style: TextStyle(color: label, fontSize: 12),
                    ),
                  ),
              ],
              onChanged: (v) {
                onSelectTilesetId(v);
              },
            ),
            if (selectedTilesetId != null && selectedTilesetId!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Détails',
                style: TextStyle(
                  color: subtle,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Nom technique : $selectedTilesetId',
                style: TextStyle(color: subtle, fontSize: 11),
              ),
              ..._pathLine(subtle, sortedTilesets, selectedTilesetId),
            ],
          ] else ...[
            Text(
              'Sélecteur d’image non connecté pour l’instant.',
              style: TextStyle(color: label, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Pour ce prototype, renseignez temporairement l’identifiant technique du jeu d’images dans Options avancées.',
              style: TextStyle(color: subtle, fontSize: 11, height: 1.3),
            ),
          ],
        ],
      ),
    );
  }

  String? get _valueForDropdown {
    final id = selectedTilesetId;
    if (id == null || id.isEmpty) {
      return null;
    }
    return id;
  }
}

List<Widget> _pathLine(
  Color subtle,
  List<ProjectTilesetEntry> sortedTilesets,
  String? selectedTilesetId,
) {
  if (selectedTilesetId == null) {
    return const [];
  }
  for (final e in sortedTilesets) {
    if (e.id == selectedTilesetId) {
      return [
        const SizedBox(height: 2),
        Text(
          e.relativePath,
          style: TextStyle(color: subtle, fontSize: 10.5),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ];
    }
  }
  return const [];
}
