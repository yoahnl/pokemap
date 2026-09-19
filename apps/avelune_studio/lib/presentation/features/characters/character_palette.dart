import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../shared/widgets/layout/studio_palette_card.dart';
import '../map_workspace/map_workspace_visuals.dart';
import 'character_workspace_visuals.dart';

class CharacterPalette extends StatefulWidget {
  const CharacterPalette({
    super.key,
    required this.project,
    required this.visuals,
    required this.onPick,
    this.selectedId,
    this.query = '',
    this.onQueryChanged,
    this.scrollOffset = 0,
    this.onScrollChanged,
  });
  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;
  final ValueChanged<ProjectCharacterEntry> onPick;
  final String? selectedId;
  final String query;
  final ValueChanged<String>? onQueryChanged;
  final double scrollOffset;
  final ValueChanged<double>? onScrollChanged;
  @override
  State<CharacterPalette> createState() => _CharacterPaletteState();
}

class _CharacterPaletteState extends State<CharacterPalette> {
  late final _search = TextEditingController(text: widget.query);
  late final ScrollController _scroll = ScrollController(
    initialScrollOffset: widget.scrollOffset,
  )..addListener(() => widget.onScrollChanged?.call(_scroll.offset));
  late List<ProjectCharacterEntry> _visible;

  @override
  void initState() {
    super.initState();
    _filter();
  }

  @override
  void didUpdateWidget(CharacterPalette oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.project != widget.project) _filter();
  }

  void _filter() {
    final query = _search.text.trim().toLowerCase();
    _visible =
        widget.project.characters.where((character) {
          return query.isEmpty ||
              '${character.name} ${character.tags.join(' ')}'
                  .toLowerCase()
                  .contains(query);
        }).toList()..sort((a, b) {
          final order = a.sortOrder.compareTo(b.sortOrder);
          return order == 0 ? a.name.compareTo(b.name) : order;
        });
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        key: const ValueKey('character-search'),
        controller: _search,
        decoration: const InputDecoration(
          hintText: 'Chercher un personnage',
          prefixIcon: Icon(Icons.search, size: 18),
        ),
        onChanged: (value) {
          widget.onQueryChanged?.call(value);
          setState(_filter);
        },
      ),
      const SizedBox(height: 8),
      Expanded(
        child: _visible.isEmpty
            ? Text(
                widget.project.characters.isEmpty
                    ? 'Aucun personnage préparé dans ce projet. Préparez ses sprites dans Character Studio de PokéMap, puis rouvrez le projet.'
                    : 'Aucun personnage ne correspond à cette recherche.',
              )
            : GridView.builder(
                controller: _scroll,
                key: const PageStorageKey('character-catalog'),
                scrollCacheExtent: const ScrollCacheExtent.pixels(0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent:
                      104 +
                      16 * (MediaQuery.textScalerOf(context).scale(1) - 1),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: _visible.length,
                itemBuilder: (context, index) {
                  final character = _visible[index];
                  final visuals = widget.visuals;
                  return StudioPaletteCard(
                    key: ValueKey('character-${character.id}'),
                    name: character.name,
                    selected: widget.selectedId == character.id,
                    preview: visuals is CharacterWorkspaceVisuals
                        ? (visuals as CharacterWorkspaceVisuals)
                              .characterThumbnail(character, size: 72)
                        : const Icon(Icons.person_outline, size: 48),
                    onTap: () => widget.onPick(character),
                  );
                },
              ),
      ),
    ],
  );
}
