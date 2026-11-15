import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/map_workspace/application/map_library_commands.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_map_labels.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

typedef MapLibrarySubmit = Future<MapLibraryOutcome> Function();

Future<void> showMapLibraryFormDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  required Widget Function(VoidCallback submit) fields,
  required MapLibrarySubmit onSubmit,
}) => showDialog<void>(
  context: context,
  builder: (_) => _MapLibraryFormDialog(
    title: title,
    confirmLabel: confirmLabel,
    fields: fields,
    onSubmit: onSubmit,
  ),
);

class _MapLibraryFormDialog extends StatefulWidget {
  const _MapLibraryFormDialog({
    required this.title,
    required this.confirmLabel,
    required this.fields,
    required this.onSubmit,
  });

  final String title;
  final String confirmLabel;
  final Widget Function(VoidCallback submit) fields;
  final MapLibrarySubmit onSubmit;

  @override
  State<_MapLibraryFormDialog> createState() => _MapLibraryFormDialogState();
}

class _MapLibraryFormDialogState extends State<_MapLibraryFormDialog> {
  var _busy = false;
  String? _error;

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final outcome = await widget.onSubmit();
    if (!mounted) return;
    if (outcome.ok) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = false;
      _error = context.l10n.mapLibraryProblem(outcome);
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    key: const ValueKey('map-library-dialog'),
    title: Text(widget.title),
    content: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          widget.fields(_submit),
          if (_error case final error?) ...[
            const SizedBox(height: StudioSpacing.l),
            StudioNotice(
              error,
              key: const ValueKey('map-library-dialog-error'),
              isError: true,
            ),
          ],
        ],
      ),
    ),
    actions: [
      StudioButton(
        label: context.l10n.mapLibraryCancel,
        secondary: true,
        onPressed: _busy ? null : () => Navigator.of(context).pop(),
      ),
      StudioButton(
        key: const ValueKey('map-library-dialog-confirm'),
        label: widget.confirmLabel,
        loading: _busy,
        onPressed: _submit,
      ),
    ],
  );
}

class MapLibraryTextField extends StatelessWidget {
  const MapLibraryTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.onSubmitted,
    this.autofocus = false,
    this.digitsOnly = false,
  });

  final TextEditingController controller;
  final String label;
  final VoidCallback onSubmitted;
  final bool autofocus;
  final bool digitsOnly;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    autofocus: autofocus,
    keyboardType: digitsOnly ? TextInputType.number : null,
    inputFormatters: digitsOnly
        ? [FilteringTextInputFormatter.digitsOnly]
        : null,
    onSubmitted: (_) => onSubmitted(),
    decoration: InputDecoration(isDense: true, labelText: label),
  );
}

Future<void> showMapBuilderNewMapDialog(
  BuildContext context,
  MapLibraryCommands commands, {
  String? groupId,
}) {
  final l10n = context.l10n;
  final name = TextEditingController();
  final size = commands.defaultSize;
  final width = TextEditingController(text: '${size.width}');
  final height = TextEditingController(text: '${size.height}');
  var folder = groupId ?? '';
  final options = l10n.mapLibraryFolderOptions(
    commands.maps.project?.groups ?? const [],
  );
  return showMapLibraryFormDialog(
    context,
    title: l10n.mapLibraryNewMapTitle,
    confirmLabel: l10n.mapLibraryCreate,
    onSubmit: () => commands.createMap(
      name: name.text,
      width: int.tryParse(width.text) ?? 0,
      height: int.tryParse(height.text) ?? 0,
      groupId: folder.isEmpty ? null : folder,
    ),
    fields: (submit) => StatefulBuilder(
      builder: (context, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MapLibraryTextField(
            key: const ValueKey('map-library-new-name'),
            controller: name,
            label: l10n.mapLibraryName,
            onSubmitted: submit,
            autofocus: true,
          ),
          const SizedBox(height: StudioSpacing.l),
          Row(
            children: [
              Expanded(
                child: MapLibraryTextField(
                  key: const ValueKey('map-library-new-width'),
                  controller: width,
                  label: l10n.mapLibraryWidth,
                  onSubmitted: submit,
                  digitsOnly: true,
                ),
              ),
              const SizedBox(width: StudioSpacing.l),
              Expanded(
                child: MapLibraryTextField(
                  key: const ValueKey('map-library-new-height'),
                  controller: height,
                  label: l10n.mapLibraryHeight,
                  onSubmitted: submit,
                  digitsOnly: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: StudioSpacing.l),
          StudioSelect(
            label: l10n.mapLibraryFolder,
            value: folder,
            options: options,
            onChanged: (value) => setState(() => folder = value),
          ),
          const SizedBox(height: StudioSpacing.m),
          Text(
            commands.dimension == ProjectDimension.threeD
                ? l10n.mapLibraryKind3d
                : l10n.mapLibraryKind2d,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> showMapBuilderFolderNameDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  required Future<MapLibraryOutcome> Function(String name) onSubmit,
  String initial = '',
}) {
  final name = TextEditingController(text: initial);
  return showMapLibraryFormDialog(
    context,
    title: title,
    confirmLabel: confirmLabel,
    onSubmit: () => onSubmit(name.text),
    fields: (submit) => MapLibraryTextField(
      key: const ValueKey('map-library-folder-name'),
      controller: name,
      label: context.l10n.mapLibraryName,
      onSubmitted: submit,
      autofocus: true,
    ),
  );
}

Future<void> showMapBuilderMoveDialog(
  BuildContext context,
  MapLibraryCommands commands,
  ProjectMapEntry map,
) {
  final l10n = context.l10n;
  var folder = map.groupId ?? '';
  final options = l10n.mapLibraryFolderOptions(
    commands.maps.project?.groups ?? const [],
  );
  return showMapLibraryFormDialog(
    context,
    title: l10n.mapLibraryMoveTitle(map.name),
    confirmLabel: l10n.mapLibraryMoveConfirm,
    onSubmit: () => commands.moveMap(map.id, folder.isEmpty ? null : folder),
    fields: (_) => StatefulBuilder(
      builder: (context, setState) => StudioSelect(
        label: l10n.mapLibraryFolder,
        value: folder,
        options: options,
        onChanged: (value) => setState(() => folder = value),
      ),
    ),
  );
}
