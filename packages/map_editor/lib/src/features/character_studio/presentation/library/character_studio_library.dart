import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../application/character_studio_media_resolver.dart';
import '../../../../theme/theme.dart';
import '../../../../ui/design_system/design_system.dart';
import '../character_studio_character_metrics.dart';
import '../preview/character_studio_sprite_thumbnail.dart';

enum CharacterStudioLibraryFilter { all, players, npc, incomplete }

final class CharacterCreateDraft {
  const CharacterCreateDraft({
    required this.name,
    required this.tilesetId,
    this.frameWidth = 1,
    this.frameHeight = 2,
  });

  final String name;
  final String tilesetId;
  final int frameWidth;
  final int frameHeight;
}

class CharacterStudioLibrary extends StatefulWidget {
  const CharacterStudioLibrary({
    super.key,
    required this.project,
    required this.selectedCharacterId,
    required this.onSelect,
    required this.onCreate,
    this.isSaving = false,
    this.resolveTilesetPath,
    this.canCreate,
    this.projectRootPath,
    this.projectRevision = '0',
    this.mediaResolver,
  });

  final ProjectManifest project;
  final String? selectedCharacterId;
  final ValueChanged<String> onSelect;
  final ValueChanged<CharacterCreateDraft> onCreate;
  final bool isSaving;
  final String? Function(String tilesetId)? resolveTilesetPath;
  final Future<bool> Function()? canCreate;
  final String? projectRootPath;
  final String projectRevision;
  final CharacterStudioMediaResolverContract? mediaResolver;

  @override
  State<CharacterStudioLibrary> createState() => _CharacterStudioLibraryState();
}

class _CharacterStudioLibraryState extends State<CharacterStudioLibrary> {
  CharacterStudioLibraryFilter _filter = CharacterStudioLibraryFilter.all;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final readiness = analyzeCharacterStudioReadiness(
      manifest: widget.project,
      requiredCharacterIds: widget.project.characters
          .map((character) => character.id)
          .toSet(),
    );
    final characters = _visibleCharacters(readiness);
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PokeMapSectionHeader(
            title: 'Personnages',
            description: '${widget.project.characters.length} dans le projet',
            trailing: PokeMapBadge(
              label: '${widget.project.characters.length}',
              variant: PokeMapBadgeVariant.info,
            ),
          ),
          const SizedBox(height: 12),
          PokeMapTextField(
            label: 'Rechercher',
            fieldKey: const ValueKey<String>('character-library-search'),
            hintText: 'Nom ou tag…',
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 10),
          PokeMapSegmentedTabs(
            tabs: [
              _filterTab(
                key: const ValueKey<String>('character-filter-all'),
                label: 'Tous',
                filter: CharacterStudioLibraryFilter.all,
              ),
              _filterTab(
                key: const ValueKey<String>('character-filter-players'),
                label: 'Joueurs',
                filter: CharacterStudioLibraryFilter.players,
              ),
              _filterTab(
                key: const ValueKey<String>('character-filter-npc'),
                label: 'PNJ',
                filter: CharacterStudioLibraryFilter.npc,
              ),
              _filterTab(
                key: const ValueKey<String>('character-filter-incomplete'),
                label: 'À compléter',
                filter: CharacterStudioLibraryFilter.incomplete,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: characters.isEmpty
                ? const PokeMapEmptyState(
                    title: 'Aucun résultat',
                    description:
                        'Modifiez la recherche ou choisissez un autre filtre.',
                    icon: Icon(CupertinoIcons.person_crop_circle_badge_xmark),
                    compact: true,
                  )
                : ListView.separated(
                    itemCount: characters.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final character = characters[index];
                      final thumbnail = characterStudioThumbnailSelection(
                        character,
                      );
                      final assetId = thumbnail.sourceAssetId;
                      final root = widget.projectRootPath?.trim();
                      final portableRequest =
                          assetId != null &&
                              root != null &&
                              root.isNotEmpty &&
                              widget.mediaResolver != null
                          ? CharacterStudioMediaRequest(
                              projectRootPath: root,
                              assetId: assetId,
                              projectRevision: widget.projectRevision,
                            )
                          : null;
                      return _CharacterLibraryCard(
                        character: character,
                        isSelected: character.id == widget.selectedCharacterId,
                        isPlayer:
                            widget.project.settings.defaultPlayerCharacterId ==
                            character.id,
                        diagnostics: readiness.forCharacter(character.id),
                        imagePath: portableRequest == null
                            ? widget.resolveTilesetPath?.call(
                                character.tilesetId,
                              )
                            : null,
                        mediaResolver: portableRequest == null
                            ? null
                            : widget.mediaResolver,
                        mediaRequest: widget.mediaResolver == null
                            ? null
                            : portableRequest,
                        thumbnailSource: thumbnail.source,
                        usesPixelCoordinates: portableRequest != null,
                        framePixelWidth:
                            character.frameWidth *
                            widget.project.settings.tileWidth,
                        framePixelHeight:
                            character.frameHeight *
                            widget.project.settings.tileHeight,
                        onTap: widget.isSaving
                            ? null
                            : () => widget.onSelect(character.id),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          PokeMapButton(
            key: const ValueKey<String>('character-create-button'),
            onPressed: widget.project.tilesets.isEmpty || widget.isSaving
                ? null
                : () => unawaited(_createCharacter()),
            disabledReason: widget.project.tilesets.isEmpty
                ? 'Importez d’abord un tileset de personnages.'
                : widget.isSaving
                ? 'Une sauvegarde est déjà en cours.'
                : null,
            leading: const Icon(CupertinoIcons.add),
            child: const Text('Nouveau personnage'),
          ),
        ],
      ),
    );
  }

  List<ProjectCharacterEntry> _visibleCharacters(
    CharacterStudioReadinessReport readiness,
  ) {
    final normalizedQuery = _query.trim().toLowerCase();
    final defaultId = widget.project.settings.defaultPlayerCharacterId;
    final result = widget.project.characters.where((character) {
      final matchesFilter = switch (_filter) {
        CharacterStudioLibraryFilter.all => true,
        CharacterStudioLibraryFilter.players => character.id == defaultId,
        CharacterStudioLibraryFilter.npc => character.id != defaultId,
        CharacterStudioLibraryFilter.incomplete =>
          readiness.forCharacter(character.id).isNotEmpty,
      };
      if (!matchesFilter) return false;
      if (normalizedQuery.isEmpty) return true;
      return character.name.toLowerCase().contains(normalizedQuery) ||
          character.tags.any(
            (tag) => tag.toLowerCase().contains(normalizedQuery),
          );
    }).toList();
    result.sort((left, right) {
      final byOrder = left.sortOrder.compareTo(right.sortOrder);
      return byOrder != 0 ? byOrder : left.name.compareTo(right.name);
    });
    return result;
  }

  PokeMapSegmentedTab _filterTab({
    required Key key,
    required String label,
    required CharacterStudioLibraryFilter filter,
  }) {
    return PokeMapSegmentedTab(
      key: key,
      label: label,
      selected: _filter == filter,
      onTap: () => setState(() => _filter = filter),
    );
  }

  Future<void> _createCharacter() async {
    if (widget.canCreate != null && !await widget.canCreate!()) return;
    if (!mounted) return;
    final draft = await showCharacterCreateDialog(
      context: context,
      tilesets: widget.project.tilesets,
    );
    if (draft != null && mounted) widget.onCreate(draft);
  }
}

class _CharacterLibraryCard extends StatelessWidget {
  const _CharacterLibraryCard({
    required this.character,
    required this.isSelected,
    required this.isPlayer,
    required this.diagnostics,
    required this.imagePath,
    required this.mediaResolver,
    required this.mediaRequest,
    required this.thumbnailSource,
    required this.usesPixelCoordinates,
    required this.framePixelWidth,
    required this.framePixelHeight,
    required this.onTap,
  });

  final ProjectCharacterEntry character;
  final bool isSelected;
  final bool isPlayer;
  final List<CharacterStudioReadinessDiagnostic> diagnostics;
  final String? imagePath;
  final CharacterStudioMediaResolverContract? mediaResolver;
  final CharacterStudioMediaRequest? mediaRequest;
  final TilesetSourceRect thumbnailSource;
  final bool usesPixelCoordinates;
  final int framePixelWidth;
  final int framePixelHeight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      key: ValueKey<String>('character-card-${character.id}'),
      selected: isSelected,
      onTap: onTap,
      keyboardInteractive: true,
      semanticLabel: 'Sélectionner ${character.name}',
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CharacterStudioSpriteThumbnail(
            key: ValueKey<String>('character-sprite-thumbnail-${character.id}'),
            semanticLabel: 'Aperçu du sprite de ${character.name}',
            imagePath: imagePath,
            mediaResolver: mediaResolver,
            mediaRequest: mediaRequest,
            source: thumbnailSource,
            framePixelWidth: framePixelWidth,
            framePixelHeight: framePixelHeight,
            usesPixelCoordinates: usesPixelCoordinates,
            size: 42,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        character.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.pokeMapColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (isPlayer)
                      const PokeMapBadge(
                        label: 'Jouable',
                        variant: PokeMapBadgeVariant.success,
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '${character.portraits.length} portraits · '
                  '${characterStudioAnimationCount(character)} animations',
                  style: TextStyle(
                    color: context.pokeMapColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (character.tags.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: [
                      for (final tag in character.tags.take(2))
                        PokeMapBadge(label: tag),
                      if (diagnostics.isNotEmpty)
                        PokeMapBadge(
                          label: '${diagnostics.length} à compléter',
                          variant: PokeMapBadgeVariant.warning,
                        ),
                    ],
                  ),
                ] else if (diagnostics.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  PokeMapBadge(
                    label: '${diagnostics.length} à compléter',
                    variant: PokeMapBadgeVariant.warning,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<CharacterCreateDraft?> showCharacterCreateDialog({
  required BuildContext context,
  required List<ProjectTilesetEntry> tilesets,
}) async {
  if (tilesets.isEmpty) return null;
  final nameController = TextEditingController();
  var tilesetId = tilesets.first.id;
  String? nameError;
  final navigator = Navigator.of(context, rootNavigator: true);
  final route = DialogRoute<CharacterCreateDraft>(
    context: context,
    barrierDismissible: false,
    themes: InheritedTheme.capture(from: context, to: navigator.context),
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => PokeMapDialog(
        title: 'Nouveau personnage',
        icon: CupertinoIcons.person_crop_circle_badge_plus,
        footer: Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            PokeMapButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              variant: PokeMapButtonVariant.secondary,
              child: const Text('Annuler'),
            ),
            PokeMapButton(
              key: const ValueKey<String>('character-create-confirm'),
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  setDialogState(() => nameError = 'Le nom est obligatoire.');
                  return;
                }
                Navigator.of(
                  dialogContext,
                ).pop(CharacterCreateDraft(name: name, tilesetId: tilesetId));
              },
              child: const Text('Créer le personnage'),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PokeMapTextField(
              label: 'Nom du personnage',
              controller: nameController,
              fieldKey: const ValueKey<String>('character-create-name'),
              hintText: 'Ex. Élia',
              errorText: nameError,
              autofocus: true,
              onChanged: (_) {
                if (nameError != null) {
                  setDialogState(() => nameError = null);
                }
              },
            ),
            const SizedBox(height: 14),
            PokeMapDropdownField<String>(
              label: 'Planche de sprites',
              value: tilesetId,
              items: [
                for (final tileset in tilesets)
                  PokeMapDropdownItem<String>(
                    value: tileset.id,
                    label: tileset.name,
                  ),
              ],
              onChanged: (value) => setDialogState(() => tilesetId = value),
            ),
          ],
        ),
      ),
    ),
  );
  final result = await navigator.push(route);
  await route.completed;
  nameController.dispose();
  return result;
}
