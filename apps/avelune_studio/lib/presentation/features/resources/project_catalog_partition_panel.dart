import 'package:flutter/material.dart';

import '../../shared/widgets/dialogs/studio_review_dialog.dart';
import '../../shell/studio_home_navigation.dart';

class ProjectCatalogPartitionPanel extends StatefulWidget {
  const ProjectCatalogPartitionPanel({
    super.key,
    required this.partition,
    required this.reopen,
    required this.registerExitGuard,
    required this.childBuilder,
    required this.home,
  });

  final Future<void> Function() partition;
  final Future<void> Function() reopen;
  final void Function(Future<bool> Function()?) registerExitGuard;
  final Widget Function(void Function(Future<bool> Function()?)) childBuilder;
  final StudioHomeNavigation home;

  @override
  State<ProjectCatalogPartitionPanel> createState() =>
      _ProjectCatalogPartitionPanelState();
}

class _ProjectCatalogPartitionPanelState
    extends State<ProjectCatalogPartitionPanel> {
  Future<bool> Function()? childGuard;
  bool busy = false;
  String? error;

  Future<bool> allowExit() async => !busy && (await childGuard?.call() ?? true);

  @override
  void initState() {
    super.initState();
    widget.registerExitGuard(allowExit);
    publishAction();
  }

  void publishAction() => widget.home.updateLibraryOptimization(
    onOptimize: partition,
    busy: busy,
    error: error,
  );

  @override
  void dispose() {
    if (widget.home.onOptimizeLibrary == partition) {
      widget.home.updateLibraryOptimization();
    }
    widget.registerExitGuard(null);
    super.dispose();
  }

  Future<void> partition() async {
    if (!await allowExit() || !mounted) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => StudioReviewDialog(
        title: 'Optimiser la bibliothèque ?',
        content: const Text(
          'La bibliothèque chargera les ressources à la demande pour accélérer la recherche et l’ouverture. Les cartes et leurs images seront conservées. Le projet sera rouvert automatiquement ; cette préparation ne s’annule pas dans l’historique.',
        ),
        confirmLabel: 'Optimiser et rouvrir',
        onConfirmed: () => Navigator.pop(context, true),
        onCancelled: () => Navigator.pop(context, false),
      ),
    );
    if (approved != true || !mounted) return;
    setState(() {
      busy = true;
      error = null;
    });
    publishAction();
    try {
      await widget.partition();
      await widget.reopen();
    } catch (failure) {
      if (mounted) {
        setState(
          () => error =
              'La conversion ou sa réouverture n’a pas pu aboutir : $failure',
        );
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
        publishAction();
      }
    }
  }

  @override
  Widget build(BuildContext context) => AbsorbPointer(
    absorbing: busy,
    child: widget.childBuilder((guard) => childGuard = guard),
  );
}
