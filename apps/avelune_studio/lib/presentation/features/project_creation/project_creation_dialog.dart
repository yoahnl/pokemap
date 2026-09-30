import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_authoring/map_authoring_project_creation.dart';
import '../../../features/project_creation/application/project_creation_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../theme/studio_tokens.dart';
import 'project_creation_steps.dart';
import 'project_creation_stepper.dart';
import 'project_creation_preview.dart';

class ProjectCreationDialog extends StatefulWidget {
  const ProjectCreationDialog({
    super.key,
    required this.port,
    required this.chooseParent,
    required this.openCreated,
  });
  final ProjectCreationPort port;
  final Future<String?> Function() chooseParent;
  final Future<bool> Function(ProjectCreationReceipt) openCreated;

  @override
  State<ProjectCreationDialog> createState() => _ProjectCreationDialogState();
}

class _ProjectCreationDialogState extends State<ProjectCreationDialog> {
  late final controller = ProjectCreationController(widget.port);
  final _focus = FocusNode();
  bool _selecting = false, _opening = false;
  String? _openError;
  bool get _canClose => controller.canClose && !_opening && !_selecting;
  @override
  void initState() {
    super.initState();
    controller.addListener(_refresh);
    controller.loadPreview();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _close() {
    if (_canClose) {
      Navigator.of(context).pop();
    } else if (controller.canCancel) {
      controller.cancel();
    }
  }

  Future<void> _chooseParent() async {
    if (_selecting) return;
    setState(() => _selecting = true);
    try {
      final path = await widget.chooseParent();
      if (!mounted || path == null) return;
      controller.change(() => controller.parentPath = path);
      await controller.checkDestination();
    } catch (_) {
      if (mounted) {
        controller.error = 'Le sélecteur de dossier est indisponible.';
      }
    } finally {
      if (mounted) setState(() => _selecting = false);
    }
  }

  Future<void> _create() async {
    FocusScope.of(context).unfocus();
    final receipt = await controller.create();
    if (!mounted) return;
    if (receipt != null) {
      await _open(receipt);
    } else if (controller.cancelled && controller.canClose) {
      _close();
    }
  }

  Future<void> _open(ProjectCreationReceipt receipt) async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _openError = null;
    });
    var opened = false;
    try {
      opened = await widget.openCreated(receipt);
    } catch (_) {
      opened = false;
    }
    if (!mounted) return;
    setState(() {
      _opening = false;
      if (!opened) {
        _openError =
            'Projet créé et conservé à cet emplacement. '
            'L’ouverture n’a pas abouti ou le basculement a été annulé. '
            'Votre projet courant reste disponible.';
      }
    });
    if (opened) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    controller.removeListener(_refresh);
    controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bounds = MediaQuery.sizeOf(context);
    return PopScope(
      canPop: _canClose,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && controller.canCancel) controller.cancel();
      },
      child: CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): _close},
        child: Focus(
          focusNode: _focus,
          autofocus: true,
          child: Dialog(
            insetPadding: const EdgeInsets.all(24),
            backgroundColor: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(StudioMetrics.panelRadius),
              side: BorderSide(color: colors.outline),
            ),
            child: SizedBox(
              width: 960,
              height: (bounds.height - 48).clamp(0, 720),
              child: Padding(
                padding: const EdgeInsets.all(StudioMetrics.panelPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Nouveau projet',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          key: const ValueKey('creation-close'),
                          tooltip: _canClose
                              ? 'Fermer le créateur'
                              : 'Attendez la fin de la création',
                          onPressed: _canClose || controller.canCancel
                              ? _close
                              : null,
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ProjectCreationStepper(step: controller.step),
                    const SizedBox(height: 24),
                    Expanded(
                      child: SingleChildScrollView(
                        key: const ValueKey('creation-content-scroll'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LayoutBuilder(
                              builder: (context, bounds) {
                                final form = ProjectCreationSteps(
                                  controller: controller,
                                  chooseParent: _chooseParent,
                                );
                                if (bounds.maxWidth < 700 ||
                                    MediaQuery.textScalerOf(context).scale(1) >
                                        1.25) {
                                  return form;
                                }
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: form),
                                    const SizedBox(width: 24),
                                    SizedBox(
                                      width: 228,
                                      child: ProjectCreationPreview(
                                        controller: controller,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            if ((controller.error != null &&
                                    !(controller.step == 0 &&
                                        controller.errorField != null)) ||
                                _openError != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                controller.error ?? _openError!,
                                style: TextStyle(color: colors.error),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        if (controller.step > 0 && controller.step < 4)
                          StudioButton(
                            label: 'Précédent',
                            icon: Icons.arrow_back,
                            secondary: true,
                            onPressed: _selecting || controller.checking
                                ? null
                                : () {
                                    _focus.requestFocus();
                                    controller.previous();
                                  },
                          ),
                        StudioButton(
                          label: controller.running
                              ? controller.canCancel
                                    ? 'Annuler la préparation'
                                    : 'Écriture en cours'
                              : 'Annuler',
                          secondary: true,
                          onPressed: _canClose || controller.canCancel
                              ? _close
                              : null,
                        ),
                        if (controller.step < 3)
                          StudioButton(
                            label: 'Suivant',
                            icon: Icons.arrow_forward,
                            onPressed: () {
                              _focus.requestFocus();
                              controller.next();
                            },
                          ),
                        if (controller.step == 3)
                          StudioButton(
                            key: const ValueKey('create-project-confirm'),
                            label: 'Créer le projet',
                            icon: Icons.add,
                            loading: controller.checking || _selecting,
                            onPressed: controller.destination == null
                                ? null
                                : _create,
                          ),
                        if (controller.step == 4 &&
                            !controller.running &&
                            controller.receipt == null)
                          StudioButton(
                            label: 'Revenir à la destination',
                            onPressed: controller.retry,
                          ),
                        if (controller.receipt != null)
                          StudioButton(
                            label: 'Ouvrir le projet créé',
                            icon: Icons.folder_open,
                            loading: _opening,
                            onPressed: () => _open(controller.receipt!),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
