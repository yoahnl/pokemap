import 'dart:async';
import 'package:flutter/material.dart';

import '../../../features/game_export/domain/studio_game_export_port.dart';
import '../../shared/widgets/buttons/studio_action_card.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_badge.dart';
import '../../shared/widgets/feedback/studio_icon_tile.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'studio_game_export_name.dart';

part 'studio_game_export_content.dart';
part 'studio_game_export_layout.dart';
part 'studio_game_export_summary.dart';

class StudioGameExportPage extends StatefulWidget {
  const StudioGameExportPage({
    super.key,
    required this.controller,
    required this.prepare,
    this.preparationFailure,
    required this.hasPendingChanges,
    required this.isCurrentProject,
    required this.pickFile,
    this.onBack,
  });

  final StudioGameExportPort controller;
  final Future<bool> Function() prepare;
  final String? Function()? preparationFailure;
  final bool Function() hasPendingChanges;
  final bool Function() isCurrentProject;
  final PickGameExportFile pickFile;
  final VoidCallback? onBack;

  @override
  State<StudioGameExportPage> createState() => _StudioGameExportPageState();
}

class _StudioGameExportPageState extends State<StudioGameExportPage> {
  bool _loaded = false;
  bool _advanced = false;
  String _gameId = '';
  String _title = '';
  String _version = '0.1.0';
  String _author = '';
  String _locale = 'fr';
  String _locales = 'fr';
  bool _publication = true;
  String? _destination;
  StudioGameExportDestination? _selectedDestination;
  bool _selectingDestination = false;
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
    if (!mounted) return;
    final error = widget.controller.error ?? '';
    setState(() {
      if (error.contains('gameId') || error.contains('identifiant stable')) {
        _advanced = true;
      }
    });
  }

  void _edit(VoidCallback change) => setState(change);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _export() async {
    if (!widget.controller.canStart || _selectingDestination) return;
    final metadata = StudioGameExportMetadata(
      gameId: _gameId,
      title: _title,
      version: _version,
      author: _author,
      locale: _locale,
      locales: _locales,
    );
    setState(() => _inputError = null);
    final destination = _selectedDestination ?? await _chooseDestination();
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
    if (mounted && widget.controller.outputPath == destination.path) {
      setState(() {
        _selectedDestination = StudioGameExportDestination(
          destination.path,
          exists: true,
        );
      });
    }
  }

  Future<StudioGameExportDestination?> _chooseDestination() async {
    if (_selectingDestination || widget.controller.operationActive) return null;
    setState(() {
      _selectingDestination = true;
      _inputError = null;
    });
    final suggested = '${gameExportSlug(_title)}-$_version.avelunegame';
    try {
      final destination = await widget.pickFile(suggested);
      if (!mounted) return null;
      setState(() {
        _selectedDestination = destination;
        _destination = destination?.path;
      });
      return destination;
    } on Object catch (failure) {
      if (mounted) {
        setState(
          () => _inputError = 'Sélection du fichier impossible : $failure',
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _selectingDestination = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, bounds) => _layout(context, bounds));
}
