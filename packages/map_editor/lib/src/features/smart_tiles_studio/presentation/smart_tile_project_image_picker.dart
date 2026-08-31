import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../../ui/design_system/design_system.dart';
import '../application/smart_tile_atlas_image_loader.dart';

class SmartTileProjectImagePicker extends StatefulWidget {
  const SmartTileProjectImagePicker({
    super.key,
    required this.tilesets,
    required this.projectRootPath,
    required this.imageLoader,
  });

  final List<ProjectTilesetEntry> tilesets;
  final String? projectRootPath;
  final SmartTileAtlasImageLoader imageLoader;

  @override
  State<SmartTileProjectImagePicker> createState() =>
      _SmartTileProjectImagePickerState();
}

class _SmartTileProjectImagePickerState
    extends State<SmartTileProjectImagePicker> {
  String _query = '';
  ProjectTilesetEntry? _selectedTileset;
  SmartTileAtlasImageLoadResult? _previewResult;
  bool _isLoadingPreview = false;
  int _previewRevision = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final normalizedQuery = _query.trim().toLowerCase();
    final visibleTilesets =
        widget.tilesets
            .where((tileset) {
              if (normalizedQuery.isEmpty) {
                return true;
              }
              return tileset.name.toLowerCase().contains(normalizedQuery) ||
                  tileset.id.toLowerCase().contains(normalizedQuery) ||
                  tileset.relativePath.toLowerCase().contains(normalizedQuery);
            })
            .toList(growable: false)
          ..sort((left, right) => left.name.compareTo(right.name));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                PokeMapTextField(
                  label: 'Rechercher',
                  fieldKey: const Key('smart-tiles-source-search'),
                  autofocus: true,
                  placeholder: 'Nom, identifiant ou chemin du tileset',
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 12),
                Text(
                  '${visibleTilesets.length} résultat(s) sur ${widget.tilesets.length}',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: visibleTilesets.isEmpty
                      ? const PokeMapEmptyState(
                          title: 'Aucun tileset trouvé',
                          description: 'Essayez un autre nom ou chemin.',
                          icon: Icon(CupertinoIcons.search),
                        )
                      : ListView.builder(
                          itemCount: visibleTilesets.length,
                          itemBuilder: (context, index) {
                            final tileset = visibleTilesets[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: PokeMapAssetCard(
                                key: Key(
                                  'smart-tiles-source-tileset-${tileset.id}',
                                ),
                                thumbnail: const Icon(
                                  CupertinoIcons.photo_on_rectangle,
                                  size: 20,
                                ),
                                label: tileset.name,
                                description: tileset.relativePath,
                                selected: _selectedTileset?.id == tileset.id,
                                onPressed: () => _previewTileset(tileset),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: PokeMapPanel(
              expandChild: true,
              padding: const EdgeInsets.all(12),
              header: const Padding(
                padding: EdgeInsets.all(12),
                child: PokeMapSectionHeader(
                  title: 'Aperçu avant de choisir',
                  description:
                      'Cliquez une image dans la liste, vérifiez son contenu, puis confirmez.',
                ),
              ),
              footer: Padding(
                padding: const EdgeInsets.all(12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: PokeMapButton(
                    key: const Key('smart-tiles-picker-confirm-image'),
                    onPressed:
                        _selectedTileset != null &&
                            _previewResult?.isLoaded == true &&
                            !_isLoadingPreview
                        ? () => Navigator.of(context).pop(_selectedTileset)
                        : null,
                    disabledReason: _selectedTileset == null
                        ? 'Sélectionnez d’abord une image à prévisualiser.'
                        : 'L’image doit être lisible avant de la choisir.',
                    leading: const Icon(CupertinoIcons.check_mark, size: 15),
                    child: const Text('Utiliser cette image'),
                  ),
                ),
              ),
              child: _buildPreview(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    if (_isLoadingPreview) {
      return const Center(child: CupertinoActivityIndicator());
    }
    final result = _previewResult;
    final image = result?.image;
    if (image != null && result!.isLoaded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: Image.memory(
              image.bytes,
              key: const Key('smart-tiles-picker-image-preview'),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
              gaplessPlayback: true,
              semanticLabel: 'Aperçu de ${_selectedTileset!.name}',
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _selectedTileset!.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text('${image.width} × ${image.height} px'),
        ],
      );
    }
    if (result != null) {
      return PokeMapEmptyState(
        title: 'Aperçu indisponible',
        description: result.message,
        icon: const Icon(CupertinoIcons.exclamationmark_triangle),
        compact: true,
      );
    }
    return const PokeMapEmptyState(
      title: 'Sélectionnez une image',
      description: 'Son contenu apparaîtra ici avant toute validation.',
      icon: Icon(CupertinoIcons.photo_on_rectangle),
      compact: true,
    );
  }

  Future<void> _previewTileset(ProjectTilesetEntry tileset) async {
    final revision = ++_previewRevision;
    setState(() {
      _selectedTileset = tileset;
      _previewResult = null;
      _isLoadingPreview = true;
    });
    final result = await widget.imageLoader.load(
      projectRootPath: widget.projectRootPath,
      tileset: tileset,
    );
    if (!mounted || revision != _previewRevision) return;
    setState(() {
      _previewResult = result;
      _isLoadingPreview = false;
    });
  }
}
