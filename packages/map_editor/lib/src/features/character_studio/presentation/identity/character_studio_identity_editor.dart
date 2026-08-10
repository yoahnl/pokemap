import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';

import '../../../../theme/theme.dart';
import '../../../../ui/design_system/design_system.dart';

final class CharacterIdentityDraft {
  const CharacterIdentityDraft({
    required this.name,
    required this.tilesetId,
    required this.frameWidth,
    required this.frameHeight,
    required this.tags,
  });

  final String name;
  final String tilesetId;
  final int frameWidth;
  final int frameHeight;
  final List<String> tags;
}

class CharacterStudioIdentityEditor extends StatefulWidget {
  const CharacterStudioIdentityEditor({
    super.key,
    required this.project,
    required this.character,
    required this.isDefaultCharacter,
    required this.isSaving,
    required this.onSave,
    required this.onSetDefault,
    required this.onDelete,
  });

  final ProjectManifest project;
  final ProjectCharacterEntry character;
  final bool isDefaultCharacter;
  final bool isSaving;
  final ValueChanged<CharacterIdentityDraft> onSave;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  @override
  State<CharacterStudioIdentityEditor> createState() =>
      _CharacterStudioIdentityEditorState();
}

class _CharacterStudioIdentityEditorState
    extends State<CharacterStudioIdentityEditor> {
  late final TextEditingController _nameController;
  late final TextEditingController _frameWidthController;
  late final TextEditingController _frameHeightController;
  late final TextEditingController _tagsController;
  late String _tilesetId;
  String? _nameError;
  String? _frameWidthError;
  String? _frameHeightError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _frameWidthController = TextEditingController();
    _frameHeightController = TextEditingController();
    _tagsController = TextEditingController();
    _loadCharacter();
  }

  @override
  void didUpdateWidget(covariant CharacterStudioIdentityEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.character != widget.character) _loadCharacter();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _frameWidthController.dispose();
    _frameHeightController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedTileset = widget.project.tilesets
        .where((tileset) => tileset.id == _tilesetId)
        .firstOrNull;
    final dropdownItems = <PokeMapDropdownItem<String>>[
      if (selectedTileset == null)
        PokeMapDropdownItem<String>(
          value: _tilesetId,
          label: 'Planche introuvable',
        ),
      for (final tileset in widget.project.tilesets)
        PokeMapDropdownItem<String>(value: tileset.id, label: tileset.name),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PokeMapSectionHeader(
            title: 'Identité',
            description:
                'Informations utilisées partout dans le projet et le runtime.',
            trailing: widget.isDefaultCharacter
                ? const PokeMapBadge(
                    label: 'Personnage jouable',
                    variant: PokeMapBadgeVariant.success,
                    icon: Icon(CupertinoIcons.game_controller_solid),
                  )
                : null,
          ),
          const SizedBox(height: 10),
          PokeMapPanel(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PokeMapTextField(
                  label: 'Nom d’affichage',
                  controller: _nameController,
                  fieldKey: const ValueKey<String>('character-identity-name'),
                  errorText: _nameError,
                  onChanged: (_) {
                    if (_nameError != null) {
                      setState(() => _nameError = null);
                    }
                  },
                ),
                const SizedBox(height: 14),
                PokeMapDropdownField<String>(
                  key: const ValueKey<String>('character-identity-tileset'),
                  label: 'Planche de sprites',
                  value: _tilesetId,
                  items: dropdownItems,
                  onChanged: (value) => setState(() => _tilesetId = value),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = (constraints.maxWidth - 12) / 2;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: width,
                          child: PokeMapTextField(
                            label: 'Largeur d’une frame',
                            controller: _frameWidthController,
                            fieldKey: const ValueKey<String>(
                              'character-identity-frame-width',
                            ),
                            errorText: _frameWidthError,
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (_) {
                              if (_frameWidthError != null) {
                                setState(() => _frameWidthError = null);
                              }
                            },
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: PokeMapTextField(
                            label: 'Hauteur d’une frame',
                            controller: _frameHeightController,
                            fieldKey: const ValueKey<String>(
                              'character-identity-frame-height',
                            ),
                            errorText: _frameHeightError,
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (_) {
                              if (_frameHeightError != null) {
                                setState(() => _frameHeightError = null);
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                PokeMapTextField(
                  label: 'Rôles et tags',
                  controller: _tagsController,
                  fieldKey: const ValueKey<String>('character-identity-tags'),
                  hintText: 'héroïne, rival, marchand…',
                ),
                const SizedBox(height: 6),
                Text(
                  'Séparez librement les tags par des virgules. Ils servent à la recherche et à l’organisation éditoriale.',
                  style: TextStyle(
                    color: context.pokeMapColors.textMuted,
                    fontSize: 10,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          PokeMapPanel(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const PokeMapIconTile(
                  icon: CupertinoIcons.game_controller_solid,
                  tone: PokeMapTone.success,
                  size: 40,
                  iconSize: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rôle jouable',
                        style: TextStyle(
                          color: context.pokeMapColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.isDefaultCharacter
                            ? 'Ce personnage est utilisé au démarrage du jeu.'
                            : 'Définissez ce personnage comme avatar joueur par défaut.',
                        style: TextStyle(
                          color: context.pokeMapColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                PokeMapButton(
                  key: const ValueKey<String>('character-set-default'),
                  onPressed: widget.isDefaultCharacter || widget.isSaving
                      ? null
                      : widget.onSetDefault,
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  child: Text(
                    widget.isDefaultCharacter ? 'Actif' : 'Rendre jouable',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            runSpacing: 10,
            children: [
              PokeMapButton(
                key: const ValueKey<String>('character-delete-button'),
                onPressed: widget.isSaving ? null : widget.onDelete,
                variant: PokeMapButtonVariant.danger,
                leading: const Icon(CupertinoIcons.trash),
                child: const Text('Supprimer'),
              ),
              PokeMapButton(
                key: const ValueKey<String>('character-identity-save'),
                onPressed: widget.isSaving ? null : _save,
                isLoading: widget.isSaving,
                leading: const Icon(CupertinoIcons.checkmark_alt),
                child: const Text('Enregistrer l’identité'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _loadCharacter() {
    _nameController.text = widget.character.name;
    _frameWidthController.text = '${widget.character.frameWidth}';
    _frameHeightController.text = '${widget.character.frameHeight}';
    _tagsController.text = widget.character.tags.join(', ');
    _tilesetId = widget.character.tilesetId;
    _nameError = null;
    _frameWidthError = null;
    _frameHeightError = null;
  }

  void _save() {
    final name = _nameController.text.trim();
    final frameWidth = int.tryParse(_frameWidthController.text);
    final frameHeight = int.tryParse(_frameHeightController.text);
    setState(() {
      _nameError = name.isEmpty ? 'Le nom est obligatoire.' : null;
      _frameWidthError = frameWidth == null || frameWidth < 1
          ? 'Entrez une largeur supérieure à zéro.'
          : null;
      _frameHeightError = frameHeight == null || frameHeight < 1
          ? 'Entrez une hauteur supérieure à zéro.'
          : null;
    });
    if (_nameError != null ||
        _frameWidthError != null ||
        _frameHeightError != null) {
      return;
    }
    final tags = <String>[];
    final seen = <String>{};
    for (final rawTag in _tagsController.text.split(',')) {
      final tag = rawTag.trim();
      if (tag.isEmpty || !seen.add(tag.toLowerCase())) continue;
      tags.add(tag);
    }
    widget.onSave(
      CharacterIdentityDraft(
        name: name,
        tilesetId: _tilesetId,
        frameWidth: frameWidth!,
        frameHeight: frameHeight!,
        tags: tags,
      ),
    );
  }
}
