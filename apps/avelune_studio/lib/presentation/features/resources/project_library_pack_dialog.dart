import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import '../../../features/resources/coordination/resource_pack_transfer_controller.dart';

part 'project_library_pack_review.dart';

class ProjectLibraryPackDialog extends StatefulWidget {
  const ProjectLibraryPackDialog({super.key, required this.transfer});

  final ResourcePackTransferController transfer;

  @override
  State<ProjectLibraryPackDialog> createState() =>
      _ProjectLibraryPackDialogState();
}

class _ProjectLibraryPackDialogState extends State<ProjectLibraryPackDialog> {
  final _search = TextEditingController();
  bool _closing = false;

  ResourcePackTransferController get transfer => widget.transfer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_pick());
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    _search.clear();
    await transfer.beginImport();
    if (mounted && transfer.phase == ResourcePackTransferPhase.closed) {
      await _close();
    }
  }

  Future<void> _close() async {
    if (_closing || transfer.blocksClose) return;
    setState(() => _closing = true);
    final closed = await transfer.requestClose();
    if (!mounted) return;
    if (closed) {
      Navigator.of(context).pop();
    } else {
      setState(() => _closing = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: transfer,
    builder: (context, _) {
      final phase = transfer.phase;
      final complete = phase == ResourcePackTransferPhase.complete;
      final ready = !_closing && !transfer.operationActive;
      final (label, VoidCallback? confirm) = switch (phase) {
        ResourcePackTransferPhase.selecting => (
          'Préparer l’installation',
          ready && transfer.canPrepare
              ? () => unawaited(transfer.prepare())
              : null,
        ),
        ResourcePackTransferPhase.preview => (
          'Installer le pack',
          ready && transfer.canApply ? () => unawaited(transfer.apply()) : null,
        ),
        ResourcePackTransferPhase.reconciliationRequired => (
          'Relire la bibliothèque',
          ready ? () => unawaited(transfer.retryReconciliation()) : null,
        ),
        ResourcePackTransferPhase.recoveryRequired => (
          'Reprendre l’installation',
          ready ? () => unawaited(transfer.recover()) : null,
        ),
        ResourcePackTransferPhase.idle => (
          'Choisir un pack',
          ready ? () => unawaited(_pick()) : null,
        ),
        _ => ('Installer le pack', null),
      };
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (popped, _) {
          if (!popped) unawaited(_close());
        },
        child: StudioReviewDialog(
          title: 'Installer un pack local',
          contentWidth: 720,
          content: _review(context, ready: ready),
          confirmLabel: complete ? null : label,
          onConfirmed: confirm,
          cancelLabel: complete ? 'Fermer' : 'Annuler',
          onCancelled: _closing || transfer.blocksClose
              ? null
              : () => unawaited(_close()),
          secondaryActionLabel: phase == ResourcePackTransferPhase.preview
              ? 'Modifier la sélection'
              : null,
          onSecondaryAction: ready
              ? () => unawaited(transfer.backToSelection())
              : null,
        ),
      );
    },
  );
}
