import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/presentation/features/story/game_memory_labels.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class GameMemoryCreationForm extends StatefulWidget {
  const GameMemoryCreationForm({
    super.key,
    required this.onCreate,
    required this.onCancel,
  });

  final void Function(String label, NarrativeValueKind kind) onCreate;
  final VoidCallback onCancel;

  @override
  State<GameMemoryCreationForm> createState() => _GameMemoryCreationFormState();
}

class _GameMemoryCreationFormState extends State<GameMemoryCreationForm> {
  final _name = TextEditingController();
  var _kind = NarrativeValueKind.boolean;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _create() {
    if (_name.text.trim().isNotEmpty) widget.onCreate(_name.text, _kind);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const ValueKey('memory-new-fact-name'),
          controller: _name,
          autofocus: true,
          onSubmitted: (_) => _create(),
          decoration: InputDecoration(
            isDense: true,
            labelText: l10n.memoryCreateFactName,
          ),
        ),
        const SizedBox(height: StudioSpacing.m),
        SegmentedButton<NarrativeValueKind>(
          key: const ValueKey('memory-new-fact-kind'),
          showSelectedIcon: false,
          segments: [
            for (final kind in const [
              NarrativeValueKind.boolean,
              NarrativeValueKind.integer,
            ])
              ButtonSegment(value: kind, label: Text(l10n.memoryKind(kind))),
          ],
          selected: {_kind},
          onSelectionChanged: (value) => setState(() => _kind = value.single),
        ),
        const SizedBox(height: StudioSpacing.m),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            StudioButton(
              label: l10n.memoryCancel,
              variant: StudioButtonVariant.quiet,
              onPressed: widget.onCancel,
            ),
            const SizedBox(width: StudioSpacing.s),
            ValueListenableBuilder(
              valueListenable: _name,
              builder: (context, value, _) => StudioButton(
                key: const ValueKey('memory-new-fact-create'),
                label: l10n.memoryCreate,
                onPressed: value.text.trim().isEmpty ? null : _create,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
