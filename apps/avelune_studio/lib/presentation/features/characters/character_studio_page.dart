import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'character_studio_controller.dart';
import '../../../features/characters/application/character_studio_draft.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_tabs.dart';
import '../../shared/widgets/layout/studio_page_header.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../map_workspace/map_workspace_visuals.dart';
import 'character_workspace_visuals.dart';
import 'character_studio_animation_panel.dart';
import 'character_studio_create_dialog.dart';
import 'character_studio_library.dart';
import 'character_studio_portrait_panel.dart';
import '../../../features/resources/domain/resource_port.dart';

class CharacterStudioPage extends StatefulWidget {
  const CharacterStudioPage({
    super.key,
    required this.project,
    required this.visuals,
    required this.controller,
    required this.onBack,
    required this.onImport,
    required this.port,
    required this.onImportPortrait,
  });

  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;
  final CharacterStudioController controller;
  final VoidCallback onBack;
  final VoidCallback onImport;
  final ResourcePort port;
  final ValueChanged<String> onImportPortrait;

  @override
  State<CharacterStudioPage> createState() => _CharacterStudioPageState();
}

class _CharacterStudioPageState extends State<CharacterStudioPage> {
  late final TextEditingController _search = TextEditingController(
    text: widget.controller.query,
  );
  Timer? _ticker;
  int _elapsedMs = 0;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted && widget.controller.playing) {
        setState(() => _elapsedMs += 100);
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final controller = widget.controller;
      final character = controller.selectedCharacter;
      final draft = controller.selectedDraft;
      return LayoutBuilder(
        builder: (context, bounds) {
          final narrow =
              bounds.maxWidth < 1020 ||
              MediaQuery.textScalerOf(context).scale(14) > 20;
          final body = narrow
              ? ListView(
                  key: const ValueKey('character-studio-narrow-scroll'),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    SizedBox(height: 280, child: _library()),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 610,
                      child: _content(character, draft, compact: true),
                    ),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: bounds.maxWidth < 1250 ? 220 : 260,
                        child: _library(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _content(character, draft)),
                    ],
                  ),
                );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StudioPageHeader(
                title:
                    controller.section == CharacterStudioSection.animations &&
                        character != null
                    ? 'Animations du personnage'
                    : 'Personnages',
                description: character == null
                    ? 'Créez et animez les personnages de votre jeu.'
                    : 'Ressources / Personnages / ${character.name}',
                actions: [
                  StudioButton(
                    label: 'Retour aux ressources',
                    icon: Icons.arrow_back,
                    secondary: true,
                    onPressed: widget.onBack,
                  ),
                  StudioButton(
                    label: 'Importer une planche',
                    icon: Icons.upload_file_outlined,
                    secondary: true,
                    onPressed: widget.onImport,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: StudioTabs<CharacterStudioSection>(
                  items: const {
                    CharacterStudioSection.library: 'Bibliothèque',
                    CharacterStudioSection.identity: 'Identité',
                    CharacterStudioSection.animations: 'Animations',
                    CharacterStudioSection.portraits: 'Portraits',
                  },
                  selected: controller.section,
                  onChanged: controller.setSection,
                ),
              ),
              if (controller.error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    controller.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              Expanded(child: body),
              _footer(draft),
            ],
          );
        },
      );
    },
  );

  Widget _library() => CharacterStudioLibrary(
    project: widget.project,
    visuals: widget.visuals,
    controller: widget.controller,
    search: _search,
    onCreate: _createCharacter,
  );

  Widget _content(
    ProjectCharacterEntry? character,
    CharacterStudioDraft? draft, {
    bool compact = false,
  }) {
    if (character == null || draft == null) {
      return StudioPanel(
        children: [
          Text(
            widget.controller.selectedId == null
                ? 'Importez une planche ou créez un personnage depuis une image du projet.'
                : 'Ce personnage n’existe plus dans le projet. Son brouillon reste conservé.',
          ),
        ],
      );
    }
    if (widget.controller.section == CharacterStudioSection.animations) {
      return CharacterStudioAnimationPanel(
        project: widget.project,
        character: character,
        draft: draft,
        controller: widget.controller,
        visuals: widget.visuals,
        elapsedMs: _elapsedMs,
        compact: compact,
      );
    }
    if (widget.controller.section == CharacterStudioSection.portraits) {
      return SingleChildScrollView(
        child: CharacterStudioPortraitPanel(
          project: widget.project,
          character: character,
          controller: widget.controller,
          port: widget.port,
          onImport: widget.onImportPortrait,
        ),
      );
    }
    return StudioPanel(
      title: 'Identité',
      children: [
        StudioDraftField(
          key: ValueKey('character-name-${character.id}'),
          value: draft.name,
          label: 'Nom du personnage',
          onChanged: widget.controller.setName,
        ),
        const SizedBox(height: 14),
        Text(
          'Source : ${widget.project.tilesets.where((entry) => entry.id == character.tilesetId).firstOrNull?.name ?? 'Image manquante'}',
        ),
        const SizedBox(height: 8),
        Text('Identifiant stable : ${character.id}'),
        const SizedBox(height: 8),
        Text(
          'Dimensions : ${character.frameWidth} × ${character.frameHeight} case(s)',
        ),
        if (widget.visuals is CharacterWorkspaceVisuals) ...[
          const SizedBox(height: 20),
          (widget.visuals as CharacterWorkspaceVisuals).characterThumbnail(
            character,
            size: 150,
          ),
        ],
      ],
    );
  }

  Widget _footer(CharacterStudioDraft? draft) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            draft?.dirty == true
                ? 'Modifications non enregistrées'
                : 'Aucune modification',
          ),
        ),
        StudioButton(
          label: 'Annuler',
          secondary: true,
          onPressed: draft?.dirty == true && !widget.controller.saving
              ? widget.controller.discardSelected
              : null,
        ),
        const SizedBox(width: 8),
        StudioButton(
          label: 'Enregistrer',
          icon: Icons.save_outlined,
          loading: widget.controller.saving,
          onPressed: draft?.dirty == true && !widget.controller.saving
              ? () => unawaited(widget.controller.saveSelected())
              : null,
        ),
      ],
    ),
  );

  Future<void> _createCharacter() async {
    final request = await showCharacterStudioCreateDialog(
      context,
      widget.project,
    );
    if (request == null) return;
    await widget.controller.create(request.$1, request.$2);
  }
}
