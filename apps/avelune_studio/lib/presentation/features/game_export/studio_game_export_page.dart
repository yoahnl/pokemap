import 'dart:async';

import 'package:flutter/material.dart';

import '../../../features/game_export/domain/studio_game_export_port.dart';
import '../../../features/game_export/application/studio_game_export_workflow.dart';
import '../../../features/game_export/application/studio_game_export_mode.dart';
import '../../../features/project_settings/application/project_identity_controller.dart';
import '../../../features/verification/application/studio_failure_diagnosis.dart';
import '../../shared/widgets/buttons/studio_action_card.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_badge.dart';
import '../../shared/widgets/feedback/studio_icon_tile.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../verification/studio_failure_report.dart';
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
    this.publicationAvailable = true,
    this.onBack,
    this.identity,
    this.onEditIdentity,
    this.onOpenOwner,
  });

  final StudioGameExportPort controller;
  final Future<bool> Function() prepare;
  final String? Function()? preparationFailure;
  final bool Function() hasPendingChanges;
  final bool Function() isCurrentProject;
  final PickGameExportFile pickFile;
  final bool publicationAvailable;
  final VoidCallback? onBack;
  final ProjectIdentityController? identity;
  final VoidCallback? onEditIdentity;
  final void Function(StudioFailureOwner owner)? onOpenOwner;

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
  late final StudioGameExportModeSelection _mode;
  bool get _publication => _mode.publication;
  set _publication(bool value) => _mode.selectPublication(
    value,
    operationActive: widget.controller.operationActive,
  );
  late final StudioGameExportWorkflow _workflow;
  String? get _destination => _workflow.destination?.path;
  bool get _selectingDestination => _workflow.selectingDestination;
  String? get _inputError => _workflow.inputError;
  StreamSubscription<void>? _subscription;

  @override
  void initState() {
    super.initState();
    _mode = StudioGameExportModeSelection(
      publicationAvailable: widget.publicationAvailable,
    );
    _workflow = StudioGameExportWorkflow(
      controller: widget.controller,
      pickFile: (name) => widget.pickFile(name),
      prepare: () => widget.prepare(),
      preparationFailure: () => widget.preparationFailure?.call(),
      hasPendingChanges: () => widget.hasPendingChanges(),
      isCurrentProject: () => widget.isCurrentProject(),
      isActive: () => mounted,
      onPublished: () async {
        await widget.identity?.open();
      },
    );
    _workflow.addListener(_changed);
    _subscription = widget.controller.changes.listen((_) => _changed());
    widget.identity?.addListener(_identityChanged);
    _load();
  }

  void _identityChanged() {
    final identity = widget.identity;
    if (!mounted || identity == null || identity.loading) return;
    final shared = identity.ready ? identity.exportMetadata : identity.proposed;
    setState(() {
      _gameId = shared.gameId;
      _title = shared.title;
      _version = shared.version;
      _author = shared.author;
      _locale = shared.locale;
      _locales = shared.locales;
      _loaded = true;
    });
  }

  Future<void> _load() async {
    if (widget.identity case final identity?) {
      await widget.controller.load();
      if (!mounted) return;
      if (!identity.ready && !identity.loading) await identity.open();
      _identityChanged();
      return;
    }
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
    _workflow.removeListener(_changed);
    _workflow.dispose();
    widget.identity?.removeListener(_identityChanged);
    _subscription?.cancel();
    super.dispose();
  }

  StudioGameExportMetadata get _metadata => StudioGameExportMetadata(
    gameId: _gameId,
    title: _title,
    version: _version,
    author: _author,
    locale: _locale,
    locales: _locales,
  );

  Future<void> _export() async {
    await _workflow.run(
      metadata: _metadata,
      publication: _publication,
      confirmOverwrite: (destination) async =>
          await showDialog<bool>(
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
          ) ==
          true,
    );
  }

  Future<StudioGameExportDestination?> _chooseDestination() =>
      _workflow.chooseDestination(_metadata);

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, bounds) => _layout(context, bounds));
}
