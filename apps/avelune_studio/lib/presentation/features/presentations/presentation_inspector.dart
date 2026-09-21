import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_tabs.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'presentation_view_state.dart';
import 'presentation_clip_labels.dart';

part 'presentation_inspector_text.dart';
part 'presentation_inspector_transform.dart';
part 'presentation_inspector_animation.dart';
part 'presentation_inspector_media.dart';

class PresentationInspector extends StatelessWidget {
  const PresentationInspector({
    super.key,
    required this.asset,
    required this.view,
    required this.onPatch,
    required this.changed,
    required this.onDelete,
    this.mediaCatalog,
    this.consumers,
    this.beforeSelection,
  });
  final PresentationCinematicAsset asset;
  final PresentationViewState view;
  final bool Function(Map<String, Object?>) onPatch;
  final VoidCallback changed, onDelete;
  final ProjectMediaCatalog? mediaCatalog;
  final Widget? consumers;
  final bool Function()? beforeSelection;
  PresentationClip? get clip => view.selected;

  Widget field(
    String label,
    Object value,
    String key, {
    bool numeric = false,
    double factor = 1,
    int lines = 1,
    Map<String, Object?>? group,
    String? groupKey,
  }) => StudioCommitField(
    key: ValueKey('${clip?.id}:$label'),
    label: label,
    value: '$value',
    maxLines: lines,
    tryCommit: (text) {
      Object? parsed = numeric
          ? double.tryParse(text.replaceAll(',', '.'))
          : text;
      if (parsed is double && (!parsed.isFinite || parsed.isNaN)) parsed = null;
      if (numeric && parsed != null) {
        parsed = (parsed as double) * factor;
        if (key.endsWith('Us')) parsed = parsed.round();
      }
      final valid =
          parsed != null &&
          onPatch(
            groupKey == null
                ? {key: parsed}
                : {
                    groupKey: {...?group, key: parsed},
                  },
          );
      if (valid) {
        view.invalidFields.remove(label);
      } else {
        view.invalidFields.add(label);
      }
      changed();
      return valid;
    },
  );

  @override
  Widget build(BuildContext context) {
    final selected = clip;
    if (selected == null) {
      return const StudioPanel(
        title: 'Inspecteur',
        children: [
          StudioNotice(
            'Sélectionnez un élément dans le canevas ou la timeline.',
          ),
        ],
      );
    }
    final editable = view.editing.isClipEditable(selected.id);
    return StudioPanel(
      title: 'Élément sélectionné',
      compact: true,
      children: [
        StudioTabs(items: const {'properties': 'Propriétés', 'animations': 'Animations'},
          selected: view.inspectorTab, onChanged: (value) {
            if (beforeSelection?.call() == false) return;
            view.inspectorTab = value; changed();
          }),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  presentationClipKind(selected),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (!editable)
                  const StudioNotice(
                    'Élément verrouillé. Déverrouillez-le dans Éléments.',
                  ),
                IgnorePointer(
                  ignoring: !editable,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      field(
                        'Début (s)',
                        selected.startUs / 1000000,
                        'startUs',
                        numeric: true,
                        factor: 1000000,
                      ),
                      const SizedBox(height: 10),
                      if (selected is! PresentationMarkerClip)
                        field(
                          'Durée (s)',
                          selected.durationUs / 1000000,
                          'durationUs',
                          numeric: true,
                          factor: 1000000,
                        ),
                      const SizedBox(height: 14),
                      if (selected is PresentationTextClip && view.inspectorTab == 'properties')
                        ...textFields(selected),
                      if (view.inspectorTab == 'properties' && (selected is PresentationVisualClip ||
                          selected is PresentationAudioClip ||
                          selected is PresentationCaptionClip))
                        ...mediaFields(selected),
                      if (selected is PresentationTextClip ||
                          selected is PresentationVisualClip) ...[
                        if (view.inspectorTab == 'properties') ...transformFields(selected),
                        if (view.inspectorTab == 'animations') ...animationFields(selected),
                      ],
                      if (selected is PresentationAudioClip) ...[
                        field(
                          'Volume',
                          selected.volume,
                          'volume',
                          numeric: true,
                        ),
                        field(
                          'Fondu audio entrant (s)',
                          selected.fadeInUs / 1000000,
                          'fadeInUs',
                          numeric: true,
                          factor: 1000000,
                        ),
                        field(
                          'Fondu audio sortant (s)',
                          selected.fadeOutUs / 1000000,
                          'fadeOutUs',
                          numeric: true,
                          factor: 1000000,
                        ),
                      ],
                      if (selected is PresentationMarkerClip) ...[
                        field('Libellé du repère', selected.label, 'label'),
                        Text(
                          selected.markerKind ==
                                  PresentationMarkerKind.interactionCue
                              ? 'Interaction : les choix et les routes appartiennent à la scène.'
                              : 'Repère de montage : ne suspend pas la lecture.',
                        ),
                      ],
                      const SizedBox(height: 18),
                      ?consumers,
                      StudioButton(
                        label: 'Supprimer la sélection',
                        onPressed: editable ? onDelete : null,
                        variant: StudioButtonVariant.destructive,
                        icon: Icons.delete_outline,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
