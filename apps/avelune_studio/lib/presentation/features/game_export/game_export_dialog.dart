import 'dart:async';
import 'dart:math';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/game_export/domain/studio_game_export_port.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

import 'game_export_identity_form.dart';
import 'game_export_status.dart';

part 'game_export_dialog_actions.dart';

class GameExportDialog extends StatefulWidget {
  const GameExportDialog({
    super.key,
    required this.port,
    required this.pickFile,
    required this.prepare,
    required this.hasPendingChanges,
    required this.isCurrentProject,
    this.preparationFailure,
  });

  final StudioGameExportPort port;
  final PickGameExportFile pickFile;
  final Future<bool> Function() prepare;
  final bool Function() hasPendingChanges, isCurrentProject;
  final String? Function()? preparationFailure;

  @override
  State<GameExportDialog> createState() => _GameExportDialogState();
}

class _GameExportDialogState extends State<GameExportDialog> {
  late final StreamSubscription<void> _subscription;
  StudioGameExportMetadata? _metadata;
  StudioGameIdentityProblem? _problem;
  String? _error;
  bool _loading = true,
      _running = false,
      _attempted = false,
      _publication = false;
  bool _loadFailed = false;

  bool get _working => _loading || _running || widget.port.operationActive;

  void _change(VoidCallback action) => setState(action);

  @override
  void initState() {
    super.initState();
    _subscription = widget.port.changes.listen((_) {
      if (mounted) setState(() {});
    });
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
      _error = null;
    });
    try {
      await widget.port.load();
      if (!mounted) return;
      _loadFailed = !widget.port.canStart;
      if (widget.port.canStart) {
        final random = Random.secure();
        final token = List.generate(
          16,
          (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
        ).join();
        _metadata =
            widget.port.metadata ??
            StudioGameExportMetadata(
              gameId: 'games.local.g$token',
              title: widget.port.projectName,
              version: '0.1.0',
              author: '',
              locale: context.l10n.localeName,
              locales: context.l10n.localeName,
            );
      }
    } on Object {
      if (mounted) _loadFailed = true;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final port = widget.port;
    final current = widget.isCurrentProject();
    final metadata = _metadata;
    final loadFailed = !_loading && _loadFailed;
    final completed = _attempted && port.stage == StudioExportStage.completed;
    return PopScope(
      canPop: !_working,
      child: AlertDialog(
        key: const ValueKey('game-export-dialog'),
        title: Text(completed ? l10n.exportReady : l10n.exportGameTitle),
        content: SizedBox(
          width: 720,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_loading) ...[
                  const LinearProgressIndicator(),
                  Text(l10n.exportLoading),
                ] else if (!current)
                  StudioNotice(l10n.exportSourceUnavailable, isError: true)
                else if (loadFailed) ...[
                  StudioNotice(l10n.exportProfileLoadFailed, isError: true),
                  if (port.failure?.detail ?? port.error case final detail?)
                    ExpansionTile(
                      title: Text(l10n.exportDetails),
                      children: [SelectableText(detail)],
                    ),
                  StudioButton(
                    label: l10n.exportReload,
                    onPressed: () => unawaited(_load()),
                  ),
                ] else if (metadata != null &&
                    !completed &&
                    !port.operationActive) ...[
                  Text(l10n.exportHint),
                  const SizedBox(height: StudioSpacing.l),
                  GameExportIdentityForm(
                    value: metadata,
                    enabled: !_working,
                    problem: _problem,
                    changed: (value) => setState(() {
                      _metadata = value;
                      _problem = null;
                      _error = null;
                    }),
                  ),
                  const SizedBox(height: StudioSpacing.l),
                  StudioSelect(
                    key: const ValueKey('export-mode'),
                    label: l10n.exportMode,
                    value: _publication ? 'publication' : 'test',
                    options: {
                      'test': l10n.exportModeTest,
                      'publication': l10n.exportModePublication,
                    },
                    onChanged: _working
                        ? null
                        : (value) => setState(
                            () => _publication = value == 'publication',
                          ),
                  ),
                  Text(
                    _publication
                        ? l10n.exportPublicationHint
                        : l10n.exportTestHint,
                  ),
                  if (_problem case final problem?)
                    StudioNotice(problem.message, isError: true),
                ],
                if (_error != null && !loadFailed)
                  StudioNotice(_error!, isError: true),
                if (_attempted && current) GameExportStatus(port: port),
              ],
            ),
          ),
        ),
        actions: [
          StudioButton(
            key: const ValueKey('export-close'),
            label: l10n.exportClose,
            secondary: true,
            onPressed: _working ? null : () => Navigator.pop(context),
          ),
          if (port.canCancel)
            StudioButton(
              key: const ValueKey('export-cancel'),
              label: l10n.exportCancelAction,
              secondary: true,
              onPressed: port.cancel,
            ),
          if (!completed)
            StudioButton(
              key: const ValueKey('export-submit'),
              label: _attempted ? l10n.exportRetry : l10n.exportAction,
              onPressed:
                  current &&
                      !_working &&
                      metadata != null &&
                      port.canStart &&
                      !loadFailed
                  ? () => unawaited(_export())
                  : null,
            ),
        ],
      ),
    );
  }
}
