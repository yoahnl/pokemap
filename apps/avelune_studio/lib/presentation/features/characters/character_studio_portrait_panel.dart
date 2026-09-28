import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/resources/domain/resource_port.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/layout/studio_asset_preview.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'character_studio_controller.dart';
import 'character_studio_portrait_actions.dart';

class CharacterStudioPortraitPanel extends StatefulWidget {
  const CharacterStudioPortraitPanel({
    super.key,
    required this.project,
    required this.character,
    required this.controller,
    required this.port,
    required this.onImport,
  });

  final ProjectManifest project;
  final ProjectCharacterEntry character;
  final CharacterStudioController controller;
  final ResourcePort port;
  final ValueChanged<String> onImport;

  @override
  State<CharacterStudioPortraitPanel> createState() =>
      _CharacterStudioPortraitPanelState();
}

class _CharacterStudioPortraitPanelState
    extends State<CharacterStudioPortraitPanel> {
  final Map<String, Future<Uint8List?>> _previews = {};

  @override
  void didUpdateWidget(CharacterStudioPortraitPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.character.id != widget.character.id ||
        oldWidget.character.portraits != widget.character.portraits ||
        oldWidget.port != widget.port) {
      _previews.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final states = widget.project.characterStudioCatalog.portraitStates.toList()
      ..sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
    return StudioPanel(
      title: 'Portraits du personnage',
      compact: true,
      children: [
        Text(
          'Une expression associe une image PNG à ce personnage. Les dialogues peuvent ensuite la choisir.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        StudioButton(
          label: 'Ajouter un état',
          icon: Icons.add,
          secondary: true,
          onPressed: widget.controller.saving ? null : _createState,
        ),
        const SizedBox(height: 12),
        if (states.isEmpty)
          const Text(
            'Aucun état défini. Créez-en un pour importer un portrait.',
          ),
        for (final state in states) ...[
          _stateRow(state),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _stateRow(CharacterPortraitStateDefinition state) {
    final portrait = widget.character.portraits
        .where((entry) => entry.portraitStateId == state.id)
        .firstOrNull;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: StudioAssetPreview(
                child: portrait == null
                    ? const Icon(Icons.person_outline)
                    : FutureBuilder<Uint8List?>(
                        future: _previews.putIfAbsent(
                          '${widget.character.id}:${state.id}:${portrait.assetId}',
                          () => widget.port.readCharacterPortrait(
                            widget.character.id,
                            state.id,
                          ),
                        ),
                        builder: (context, snapshot) => switch (snapshot) {
                          AsyncSnapshot<Uint8List?>(
                            hasData: true,
                            :final data?,
                          ) =>
                            Image.memory(
                              data,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.none,
                            ),
                          AsyncSnapshot<Uint8List?>(
                            connectionState: ConnectionState.done,
                          ) =>
                            const Tooltip(
                              message: 'Image indisponible',
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          _ => const Center(child: CircularProgressIndicator()),
                        },
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    portrait == null
                        ? 'Aucune image associée'
                        : 'Portrait lié · ${portrait.fitMode.name}',
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StudioButton(
                        label: portrait == null
                            ? 'Importer un portrait'
                            : 'Changer l’image',
                        icon: Icons.upload_file_outlined,
                        onPressed: widget.controller.saving
                            ? null
                            : () => widget.onImport(state.id),
                      ),
                      if (portrait != null)
                        StudioButton(
                          label: 'Détacher',
                          secondary: true,
                          onPressed: widget.controller.saving
                              ? null
                              : () => _clear(state.id),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createState() async {
    final field = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvel état de portrait'),
        content: TextField(
          controller: field,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nom de l’état'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, field.text.trim()),
            child: const Text('Créer l’état'),
          ),
        ],
      ),
    );
    field.dispose();
    if (name == null || name.isEmpty || !mounted) return;
    await widget.controller.createPortraitState(name);
  }

  Future<void> _clear(String stateId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détacher ce portrait ?'),
        content: const Text(
          'Le lien de ce personnage sera retiré. Le fichier importé reste dans le projet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Détacher'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await widget.controller.mutate('characterStudio.character.portrait.clear', {
      'characterId': widget.character.id,
      'portraitStateId': stateId,
    });
  }
}
