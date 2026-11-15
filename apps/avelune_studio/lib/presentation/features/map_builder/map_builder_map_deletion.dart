import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/map_workspace/application/map_library_commands.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_map_labels.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

Future<void> showMapBuilderDeletionDialog(
  BuildContext context,
  MapLibraryCommands commands,
  ProjectMapEntry map,
) => showDialog<void>(
  context: context,
  builder: (_) => _MapDeletionDialog(commands: commands, map: map),
);

class _MapDeletionDialog extends StatefulWidget {
  const _MapDeletionDialog({required this.commands, required this.map});

  final MapLibraryCommands commands;
  final ProjectMapEntry map;

  @override
  State<_MapDeletionDialog> createState() => _MapDeletionDialogState();
}

class _MapDeletionDialogState extends State<_MapDeletionDialog> {
  MapLibraryDeletion? _deletion;
  var _deleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final deletion = await widget.commands.analyzeDeletion(widget.map.id);
      if (mounted) setState(() => _deletion = deletion);
    });
  }

  Future<void> _confirm(MapLibraryDeletion deletion) async {
    setState(() {
      _deleting = true;
      _error = null;
    });
    final outcome = await widget.commands.confirmDeletion(deletion);
    if (!mounted) return;
    if (outcome.ok) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _deleting = false;
      _error = context.l10n.mapLibraryProblem(outcome);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final deletion = _deletion;
    final name = widget.map.name;
    final inUse = deletion != null && deletion.usages.isNotEmpty;
    final failure = deletion?.failure;
    final close = StudioButton(
      key: const ValueKey('map-library-delete-close'),
      label: deletion != null && deletion.allowed
          ? l10n.mapLibraryCancel
          : l10n.mapLibraryClose,
      secondary: true,
      onPressed: _deleting ? null : () => Navigator.of(context).pop(),
    );
    return AlertDialog(
      key: const ValueKey('map-library-delete-dialog'),
      title: Text(
        inUse
            ? l10n.mapLibraryInUseTitle(name)
            : l10n.mapLibraryDeleteTitle(name),
      ),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (deletion == null)
              StudioLoadingState(label: l10n.mapLibraryDeleteAnalyzing(name))
            else if (inUse) ...[
              Text(l10n.mapLibraryInUseBody),
              const SizedBox(height: StudioSpacing.m),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final usage in deletion.usages)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: StudioSpacing.xs,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.link,
                              size: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            const SizedBox(width: StudioSpacing.m),
                            Expanded(child: Text(l10n.mapLibraryUsage(usage))),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ] else if (failure != null)
              StudioNotice(l10n.mapLibraryProblem(failure), isError: true)
            else
              Text(l10n.mapLibraryDeleteBody),
            if (_error case final error?) ...[
              const SizedBox(height: StudioSpacing.l),
              StudioNotice(error, isError: true),
            ],
          ],
        ),
      ),
      actions: [
        close,
        if (deletion != null && deletion.allowed)
          StudioButton(
            key: const ValueKey('map-library-delete-confirm'),
            label: l10n.mapLibraryDeleteConfirm,
            variant: StudioButtonVariant.destructive,
            loading: _deleting,
            onPressed: () => _confirm(deletion),
          ),
      ],
    );
  }
}
