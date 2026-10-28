import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/project_audio/application/project_audio_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../presentations/presentation_media_picker.dart';

class ProjectAudioPanel extends StatefulWidget {
  const ProjectAudioPanel({super.key, required this.owner, this.pickMedia});
  final ProjectAudioController owner;
  final PickPresentationMedia? pickMedia;
  @override
  State<ProjectAudioPanel> createState() => _ProjectAudioPanelState();
}

class _ProjectAudioPanelState extends State<ProjectAudioPanel>
    with WidgetsBindingObserver {
  String query = '';
  ProjectSoundCue selected = ProjectSoundCue.uiConfirm;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(open());
  }

  Future<void> open() async {
    await widget.owner.open();
    if (mounted && widget.owner.library.isEmpty) {
      await widget.owner.loadLibrary();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(widget.owner.stop());
  }

  Future<void> import() async {
    final pick = widget.pickMedia;
    if (pick == null) return;
    final file = await pick(ProjectMediaKind.audio);
    if (file != null && mounted) {
      await widget.owner.import(file.path, file.label);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(widget.owner.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.owner,
    builder: (context, _) {
      final owner = widget.owner;
      final binding = owner.preview.value.bindingFor(selected);
      final source =
          owner.pendingSources[selected] ??
          owner.preview.value.cues[selected]?.source.name ??
          'inherit';
      final descriptor = ProjectSoundCueCatalog.forCue(selected);
      final available = !owner.busy && owner.saved != null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StudioPanel(
            title: 'Bruitages du projet',
            icon: Icons.volume_up_outlined,
            children: [
              const Text(
                'Associez les sons du projet aux actions du jeu. Les réglages restent en aperçu jusqu’à leur enregistrement.',
              ),
              const SizedBox(height: 12),
              StudioSelect(
                key: const ValueKey('project-audio-cue'),
                label: 'Action du jeu',
                value: selected.wireName,
                options: {
                  for (final entry in ProjectSoundCueCatalog.entries)
                    entry.cue.wireName: '${entry.group} · ${entry.label}',
                },
                onChanged: (value) => setState(
                  () => selected = ProjectSoundCue.fromWireName(value),
                ),
              ),
              const SizedBox(height: 10),
              StudioSelect(
                key: ValueKey('project-audio-source-${selected.wireName}'),
                label: 'Son associé',
                value: source,
                options: const {
                  'inherit': 'Réglage par défaut',
                  'builtin': 'Son intégré de cette action',
                  'silent': 'Aucun son',
                  'custom': 'Son de la bibliothèque',
                },
                onChanged: available
                    ? (value) => owner.source(selected, value)
                    : null,
              ),
              const SizedBox(height: 6),
              Text(
                descriptor.legacyBuiltin
                    ? 'Cette action possède un son intégré par défaut.'
                    : 'Cette action reste silencieuse par défaut. Choisissez un son pour la personnaliser.',
              ),
              if (source == 'custom') ...[
                const SizedBox(height: 10),
                StudioSelect(
                  key: ValueKey('project-audio-media-${selected.wireName}'),
                  label: 'Son de la bibliothèque',
                  value: binding.mediaId,
                  options: {
                    if (binding.mediaId != null &&
                        !owner.library.containsKey(binding.mediaId))
                      binding.mediaId!: 'Son enregistré (hors de cette page)',
                    for (final entry in owner.library.values)
                      entry.id: entry.label,
                  },
                  onChanged: available
                      ? (value) => owner.assign(selected, value)
                      : null,
                ),
              ],
              if (source != 'silent' &&
                      binding.source != ProjectSoundSource.silent ||
                  source == 'custom') ...[
                const SizedBox(height: 10),
                StudioDraftField(
                  key: ValueKey('project-audio-gain-${selected.wireName}'),
                  label: 'Volume de cette action (%)',
                  value:
                      owner.rawGains[selected] ??
                      '${(binding.gain * 100).round()}',
                  enabled: available,
                  errorText: owner.fieldErrors[selected],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (value) => owner.gain(selected, value),
                ),
              ],
              if (owner.fieldErrors[selected] case final error?)
                Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StudioButton(
                    key: const ValueKey('save-project-audio'),
                    label: 'Enregistrer les sons',
                    icon: Icons.save_outlined,
                    onPressed:
                        available && owner.dirty && owner.fieldErrors.isEmpty
                        ? owner.save
                        : null,
                  ),
                  StudioButton(
                    label: 'Annuler les modifications',
                    secondary: true,
                    onPressed: available && owner.dirty ? owner.discard : null,
                  ),
                  StudioButton(
                    label: 'Annuler',
                    icon: Icons.undo,
                    secondary: true,
                    onPressed: available && owner.canUndo ? owner.undo : null,
                  ),
                  StudioButton(
                    label: 'Rétablir',
                    icon: Icons.redo,
                    secondary: true,
                    onPressed: available && owner.canRedo ? owner.redo : null,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                owner.dirty
                    ? 'Bruitages non enregistrés'
                    : 'Bruitages enregistrés',
              ),
              if (owner.error case final error?)
                Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
          const SizedBox(height: 12),
          StudioPanel(
            title: 'Bibliothèque de sons',
            icon: Icons.library_music_outlined,
            children: [
              StudioDraftField(
                label: 'Rechercher un son',
                value: query,
                onChanged: (value) => query = value,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StudioButton(
                    label: 'Rechercher',
                    icon: Icons.search,
                    secondary: true,
                    onPressed: owner.libraryLoading
                        ? null
                        : () => owner.loadLibrary(query: query),
                  ),
                  StudioButton(
                    key: const ValueKey('import-project-audio'),
                    label: owner.importing
                        ? 'Import du son…'
                        : 'Importer un son',
                    icon: Icons.file_upload_outlined,
                    onPressed: available && widget.pickMedia != null
                        ? import
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (final entry in owner.library.values)
                StudioChoice(
                  key: ValueKey('project-audio-entry-${entry.id}'),
                  label: entry.label,
                  selected: binding.mediaId == entry.id,
                  subtitle: 'Utiliser pour « ${descriptor.label} »',
                  onTap: available
                      ? () => owner.assign(selected, entry.id)
                      : null,
                  trailing: StudioButton(
                    label: owner.playingId == entry.id ? 'Arrêter' : 'Écouter',
                    icon: owner.playingId == entry.id
                        ? Icons.stop
                        : Icons.play_arrow,
                    secondary: true,
                    onPressed: owner.audition == null
                        ? null
                        : () => owner.listen(entry.id),
                  ),
                ),
              if (owner.libraryLoading) const Text('Chargement des sons…'),
              if (!owner.libraryLoading && owner.library.isEmpty)
                const Text(
                  'Aucun son dans la bibliothèque. Importez un fichier audio pour le choisir.',
                ),
              if (owner.nextCursor != null)
                StudioButton(
                  label: 'Afficher les sons suivants',
                  secondary: true,
                  onPressed: owner.libraryLoading
                      ? null
                      : () => owner.loadLibrary(more: true),
                ),
              if (owner.libraryError case final error?)
                Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ],
      );
    },
  );
}
