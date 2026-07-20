import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../pokemap_badge.dart';
import '../pokemap_card.dart';
import '../pokemap_dashboard_primitives.dart';
import '../pokemap_section_header.dart';
import '../pokemap_tone.dart';

enum PokeMapEventSourcePickerKind {
  draft,
  mapEntry,
  zone,
  npc,
  object,
  placedElement,
  legacy,
  outcome,
}

enum PokeMapEventSourcePickerState {
  ready,
  needsMapRepair,
  notAttachable,
  legacyCompatibility,
  draft,
}

/// Design-system option for a concrete Event source reference.
///
/// The option intentionally carries presentation facts only. Feature code
/// keeps ownership of canonical identities and receives the selected stable
/// [id] through [PokeMapEventSourcePicker.onSelected].
final class PokeMapEventSourcePickerOption {
  const PokeMapEventSourcePickerOption({
    required this.id,
    required this.label,
    required this.description,
    required this.groupLabel,
    required this.groupDescription,
    required this.typeLabel,
    required this.kind,
    required this.state,
  });

  final String id;
  final String label;
  final String description;
  final String groupLabel;
  final String groupDescription;
  final String typeLabel;
  final PokeMapEventSourcePickerKind kind;
  final PokeMapEventSourcePickerState state;

  bool get selectable =>
      state == PokeMapEventSourcePickerState.ready ||
      state == PokeMapEventSourcePickerState.draft;
}

/// Grouped, keyboard-accessible picker for spatial and outcome Event sources.
///
/// Unavailable physical owners remain visible but are excluded from pointer
/// and keyboard activation. This lets feature screens explain that repair
/// belongs to Map Editor without implementing a competing local picker.
class PokeMapEventSourcePicker extends StatelessWidget {
  const PokeMapEventSourcePicker({
    super.key,
    required this.options,
    required this.selectedId,
    required this.onSelected,
    this.enabled = true,
    this.optionKeyPrefix = 'pokemap-event-source-option-',
  });

  final List<PokeMapEventSourcePickerOption> options;
  final String selectedId;
  final ValueChanged<String> onSelected;
  final bool enabled;
  final String optionKeyPrefix;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<PokeMapEventSourcePickerOption>>{};
    for (final option in options) {
      groups.putIfAbsent(option.groupLabel, () => []).add(option);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in groups.entries) ...[
          PokeMapSectionHeader(
            title: group.key,
            description: group.value.first.groupDescription,
          ),
          for (final option in group.value) ...[
            _PokeMapEventSourceOptionCard(
              key: ValueKey('$optionKeyPrefix${option.id}'),
              option: option,
              selected: option.id == selectedId,
              enabled: enabled,
              onSelected: () => onSelected(option.id),
            ),
            const SizedBox(height: 6),
          ],
        ],
      ],
    );
  }
}

class _PokeMapEventSourceOptionCard extends StatefulWidget {
  const _PokeMapEventSourceOptionCard({
    super.key,
    required this.option,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final PokeMapEventSourcePickerOption option;
  final bool selected;
  final bool enabled;
  final VoidCallback onSelected;

  @override
  State<_PokeMapEventSourceOptionCard> createState() =>
      _PokeMapEventSourceOptionCardState();
}

class _PokeMapEventSourceOptionCardState
    extends State<_PokeMapEventSourceOptionCard> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'event source option');

  bool get _canSelect => widget.enabled && widget.option.selectable;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _focusNode
      ..canRequestFocus = _canSelect
      ..skipTraversal = !_canSelect;
    return FocusableActionDetector(
      focusNode: _focusNode,
      enabled: _canSelect,
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onSelected();
            return null;
          },
        ),
      },
      onFocusChange: (_) {
        if (mounted) setState(() {});
      },
      child: Semantics(
        button: true,
        enabled: _canSelect,
        selected: widget.selected,
        label: '${widget.option.label}, ${_stateLabel(widget.option.state)}',
        child: PokeMapCard(
          focused: _focusNode.hasFocus,
          selected: widget.selected,
          onTap: _canSelect ? widget.onSelected : null,
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PokeMapIconTile(
                icon: _icon(widget.option.kind),
                tone: _canSelect
                    ? _tone(widget.option.kind)
                    : PokeMapTone.warning,
                size: 34,
                iconSize: 16,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.option.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.option.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: [
                        PokeMapBadge(
                          label: widget.option.typeLabel,
                          variant: widget.option.kind ==
                                  PokeMapEventSourcePickerKind.outcome
                              ? PokeMapBadgeVariant.narrative
                              : PokeMapBadgeVariant.mapAccent,
                        ),
                        PokeMapBadge(
                          label: _stateLabel(widget.option.state),
                          variant: widget.option.state ==
                                      PokeMapEventSourcePickerState
                                          .needsMapRepair ||
                                  widget.option.state ==
                                      PokeMapEventSourcePickerState
                                          .notAttachable
                              ? PokeMapBadgeVariant.warning
                              : widget.option.state ==
                                      PokeMapEventSourcePickerState
                                          .legacyCompatibility
                                  ? PokeMapBadgeVariant.neutral
                                  : PokeMapBadgeVariant.success,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _stateLabel(PokeMapEventSourcePickerState state) => switch (state) {
      PokeMapEventSourcePickerState.ready => 'Disponible',
      PokeMapEventSourcePickerState.needsMapRepair =>
        'À réparer dans Map Editor',
      PokeMapEventSourcePickerState.notAttachable =>
        'Visible · non rattachable',
      PokeMapEventSourcePickerState.legacyCompatibility =>
        'Historique · à migrer',
      PokeMapEventSourcePickerState.draft => 'Brouillon',
    };

IconData _icon(PokeMapEventSourcePickerKind kind) => switch (kind) {
      PokeMapEventSourcePickerKind.draft => CupertinoIcons.clock,
      PokeMapEventSourcePickerKind.mapEntry => CupertinoIcons.map_pin_ellipse,
      PokeMapEventSourcePickerKind.zone => CupertinoIcons.scope,
      PokeMapEventSourcePickerKind.npc => CupertinoIcons.person_crop_circle,
      PokeMapEventSourcePickerKind.object => CupertinoIcons.cube_box,
      PokeMapEventSourcePickerKind.placedElement =>
        CupertinoIcons.cube_box_fill,
      PokeMapEventSourcePickerKind.legacy => CupertinoIcons.archivebox,
      PokeMapEventSourcePickerKind.outcome => CupertinoIcons.flag_fill,
    };

PokeMapTone _tone(PokeMapEventSourcePickerKind kind) => switch (kind) {
      PokeMapEventSourcePickerKind.outcome => PokeMapTone.narrative,
      PokeMapEventSourcePickerKind.draft => PokeMapTone.neutral,
      _ => PokeMapTone.map,
    };
