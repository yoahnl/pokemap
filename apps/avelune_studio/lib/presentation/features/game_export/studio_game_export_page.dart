import 'dart:async';

import 'package:flutter/material.dart';

import '../../../features/game_export/domain/studio_game_export_port.dart';
import 'studio_game_export_name.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/layout/studio_page_header.dart';
import '../../shared/widgets/layout/studio_panel.dart';

class StudioGameExportPage extends StatefulWidget {
  const StudioGameExportPage({
    super.key,
    required this.controller,
    required this.prepare,
    this.preparationFailure,
    required this.hasPendingChanges,
    required this.isCurrentProject,
    required this.pickFile,
  });

  final StudioGameExportPort controller;
  final Future<bool> Function() prepare;
  final String? Function()? preparationFailure;
  final bool Function() hasPendingChanges;
  final bool Function() isCurrentProject;
  final PickGameExportFile pickFile;

  @override
  State<StudioGameExportPage> createState() => _StudioGameExportPageState();
}

class _StudioGameExportPageState extends State<StudioGameExportPage> {
  bool _loaded = false;
  String _gameId = '';
  String _title = '';
  String _version = '0.1.0';
  String _author = '';
  String _locale = 'fr';
  String _locales = 'fr';
  bool _publication = true;
  String? _inputError;
  StreamSubscription<void>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.controller.changes.listen((_) => _changed());
    _load();
  }

  Future<void> _load() async {
    await widget.controller.load();
    if (!mounted) return;
    final profile = widget.controller.metadata;
    setState(() {
      _gameId =
          profile?.gameId ??
          'games.avelune.${gameExportSlug(widget.controller.projectName)}';
      _title = profile?.title ?? widget.controller.projectName;
      _version = profile?.version ?? '0.1.0';
      _author = profile?.author ?? '';
      _locale = profile?.locale ?? 'fr';
      _locales = profile?.locales ?? 'fr';
      _loaded = true;
    });
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _export() async {
    if (!widget.controller.canStart) return;
    final metadata = StudioGameExportMetadata(
      gameId: _gameId,
      title: _title,
      version: _version,
      author: _author,
      locale: _locale,
      locales: _locales,
    );
    setState(() => _inputError = null);
    final suggested =
        '${gameExportSlug(metadata.title)}-${metadata.version}.avelunegame';
    StudioGameExportDestination? file;
    try {
      file = await widget.pickFile(suggested);
    } on Object catch (failure) {
      if (mounted) {
        setState(
          () => _inputError = 'Sélection du fichier impossible : $failure',
        );
      }
      return;
    }
    final destination = file;
    if (destination == null || !mounted) return;
    if (destination.exists) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Remplacer ce paquet ?'),
          content: Text(
            'Le fichier ${destination.path} existe déjà. Confirmer son remplacement ?',
          ),
          actions: [
            StudioButton(
              label: 'Conserver',
              secondary: true,
              onPressed: () => Navigator.pop(dialogContext, false),
            ),
            StudioButton(
              label: 'Remplacer',
              onPressed: () => Navigator.pop(dialogContext, true),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    await widget.controller.export(
      metadata: metadata,
      outputPath: destination.path,
      overwriteConfirmed: destination.exists,
      publication: _publication,
      prepare: widget.prepare,
      preparationFailure: widget.preparationFailure,
      hasPendingChanges: widget.hasPendingChanges,
      isCurrentProject: widget.isCurrentProject,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        StudioPageHeader(
          title: 'Exporter le jeu',
          description:
              'Créez un paquet .avelunegame à installer dans Avelune Player.',
          actions: [
            if (controller.canCancel)
              StudioButton(
                label: 'Annuler',
                secondary: true,
                onPressed: controller.cancel,
              ),
          ],
        ),
        const SizedBox(height: 16),
        StudioPanel(
          title: 'Identité du paquet',
          children: [
            const Text(
              'Ces informations servent au jeu distribué. Elles ne modifient pas le titre ni l’identité du projet auteur.',
            ),
            if (!_loaded) const LinearProgressIndicator(),
            if (_loaded) ...[
              StudioDraftField(
                value: _gameId,
                label: 'Identifiant stable du jeu',
                onChanged: (value) => setState(() => _gameId = value),
              ),
              const SizedBox(height: 12),
              StudioDraftField(
                value: _title,
                label: 'Titre du jeu',
                onChanged: (value) => setState(() => _title = value),
              ),
              const SizedBox(height: 12),
              StudioDraftField(
                value: _version,
                label: 'Version du jeu',
                onChanged: (value) => setState(() => _version = value),
              ),
              const SizedBox(height: 12),
              StudioDraftField(
                value: _author,
                label: 'Auteur',
                onChanged: (value) => setState(() => _author = value),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StudioDraftField(
                      value: _locale,
                      label: 'Langue principale',
                      onChanged: (value) => setState(() => _locale = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StudioDraftField(
                      value: _locales,
                      label: 'Langues disponibles',
                      onChanged: (value) => setState(() => _locales = value),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        StudioPanel(
          title: 'Construction',
          children: [
            StudioSelect(
              label: 'Mode de validation',
              value: _publication ? 'publication' : 'localTest',
              options: const {
                'publication': 'Publication',
                'localTest': 'Test local',
              },
              onChanged: controller.busy
                  ? null
                  : (value) =>
                        setState(() => _publication = value == 'publication'),
            ),
            const SizedBox(height: 12),
            Text(
              widget.hasPendingChanges()
                  ? 'Des brouillons existent. Vous pourrez les enregistrer explicitement avant l’export.'
                  : 'L’export utilisera la version enregistrée du projet.',
            ),
            const SizedBox(height: 12),
            StudioButton(
              label: 'Choisir le fichier et exporter',
              icon: Icons.archive_outlined,
              onPressed: !_loaded || !controller.canStart ? null : _export,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_inputError != null) StudioNotice(_inputError!, isError: true),
        if (controller.error != null)
          StudioNotice(controller.error!, isError: true),
        if (controller.warning != null) StudioNotice(controller.warning!),
        if (controller.busy)
          StudioPanel(
            title: 'Export en cours',
            children: [
              const LinearProgressIndicator(),
              const SizedBox(height: 12),
              Text(switch (controller.stage) {
                StudioExportStage.preparing =>
                  'Préparation et contrôle des documents enregistrés…',
                StudioExportStage.building =>
                  'Construction et validation du paquet…',
                _ => 'Écriture et vérification du fichier…',
              }),
            ],
          ),
        if (controller.outputPath case final path?)
          StudioPanel(
            title: 'Paquet prêt',
            children: [
              SelectableText(path),
              const SizedBox(height: 8),
              Text('SHA-256 : ${controller.packageSha256}'),
              Text('Révision source : ${controller.sourceRevision}'),
            ],
          ),
      ],
    );
  }
}
