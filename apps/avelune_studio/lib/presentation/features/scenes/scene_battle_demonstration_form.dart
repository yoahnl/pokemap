import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/scenes/application/scene_battle_demonstration_draft.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_toggle_row.dart';

class SceneBattleDemonstrationForm extends StatefulWidget {
  const SceneBattleDemonstrationForm({
    super.key,
    required this.project,
    required this.value,
    required this.onChanged,
    this.loadItems,
    this.loadCaptureItems,
  });
  final ProjectManifest project;
  final SceneBattleDemonstration? value;
  final ValueChanged<SceneBattleDemonstration?> onChanged;
  final Future<Map<String, String>> Function()? loadItems;
  final Future<Map<String, String>> Function()? loadCaptureItems;

  @override
  State<SceneBattleDemonstrationForm> createState() =>
      _SceneBattleDemonstrationFormState();
}

class _SceneBattleDemonstrationFormState
    extends State<SceneBattleDemonstrationForm> {
  late Future<({Map<String, String> items, Map<String, String> captureItems})>
  _items = _load();
  Future<({Map<String, String> items, Map<String, String> captureItems})>
  _load() async => (
    items:
        await widget.loadItems?.call() ??
        {
          for (final entry in widget.value?.bagItems ?? const <BagEntry>[])
            entry.itemId: entry.itemId,
        },
    captureItems: await widget.loadCaptureItems?.call() ?? const {},
  );

  @override
  void didUpdateWidget(SceneBattleDemonstrationForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loadItems != widget.loadItems ||
        oldWidget.loadCaptureItems != widget.loadCaptureItems) {
      _items = _load();
    }
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<
        ({Map<String, String> items, Map<String, String> captureItems})
      >(
        future: _items,
        builder: (context, snapshot) {
          final choices = snapshot.data?.items ?? const <String, String>{};
          final captures =
              snapshot.data?.captureItems ?? const <String, String>{};
          final draft = SceneBattleDemonstrationDraft(
            project: widget.project,
            value: widget.value,
            items: choices,
            captureItems: captures,
          );
          final teams = draft.teams;
          final value = draft.value;
          final available = draft.available;
          final bag = draft.bag;
          final captureBag = draft.captureBag;
          void apply(void Function() edit) {
            edit();
            widget.onChanged(draft.value);
          }

          void patch(Map<String, dynamic> values) =>
              apply(() => draft.patch(values));
          void choice(int index, SceneBattleDemonstrationChoice value) =>
              apply(() => draft.choice(index, value));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StudioToggleRow(
                label: 'Démonstration automatique',
                value: value != null,
                description: 'Équipe et sac temporaires. Le joueur retrouve exactement son état après le combat.',
                onChanged: !available && value == null
                    ? null
                    : (enabled) => apply(() => draft.enable(enabled)),
              ),
              if (snapshot.hasError)
                const StudioNotice(
                  'Le catalogue des objets ne peut pas être chargé.',
                  isError: true,
                ),
              if (!available && value == null)
                const StudioNotice(
                  'Préparez une équipe solo et un objet de capture dans un projet 3D.',
                ),
              if (value != null) ...[
                StudioSelect(
                  label: 'Équipe temporaire',
                  value: value.playerTrainerId,
                  options: teams,
                  onChanged: (id) => patch({'playerTrainerId': id}),
                ),
                const SizedBox(height: 12),
                const Text('Sac temporaire'),
                for (var index = 0; index < value.bagItems.length; index++) ...[
                  StudioSelect(
                    label: 'Objet ${index + 1}',
                    value: value.bagItems[index].itemId,
                    options: draft.replacementItems(index),
                    onChanged: (id) =>
                        apply(() => draft.replaceItem(index, id)),
                  ),
                  StudioCommitField(
                    label: 'Quantité ${index + 1}',
                    value: '${value.bagItems[index].quantity}',
                    tryCommit: (text) {
                      if (!draft.quantity(index, text)) return false;
                      widget.onChanged(draft.value);
                      return true;
                    },
                  ),
                  StudioButton(
                    label: 'Retirer cet objet',
                    onPressed:
                        value.choices.any(
                          (action) =>
                              action.itemId == value.bagItems[index].itemId,
                        )
                        ? null
                        : () => apply(() => draft.removeItem(index)),
                  ),
                ],
                StudioButton(
                  label: 'Ajouter un objet',
                  onPressed: choices.keys.every(bag.containsKey)
                      ? null
                      : () => apply(draft.addItem),
                ),
                const SizedBox(height: 12),
                const Text('Actions, dans l’ordre'),
                for (var index = 0; index < value.choices.length; index++) ...[
                  StudioSelect(
                    label: 'Action ${index + 1}',
                    value: value.choices[index].kind,
                    options: {
                      'fight': 'Utiliser une capacité',
                      if (captureBag.isNotEmpty) 'capture': 'Lancer une Ball',
                    },
                    onChanged: (kind) => choice(
                      index,
                      kind == 'fight'
                          ? SceneBattleDemonstrationChoice.fight(0)
                          : SceneBattleDemonstrationChoice.capture(
                              captureBag.keys.first,
                            ),
                    ),
                  ),
                  if (value.choices[index].kind == 'fight')
                    StudioSelect(
                      label: 'Capacité ${index + 1}',
                      value: '${value.choices[index].moveIndex}',
                      options: {
                        for (var i = 0; i < 4; i++)
                          '$i': 'Emplacement ${i + 1}',
                      },
                      onChanged: (id) => choice(
                        index,
                        SceneBattleDemonstrationChoice.fight(int.parse(id)),
                      ),
                    ),
                  if (value.choices[index].kind == 'capture')
                    StudioSelect(
                      label: 'Ball ${index + 1}',
                      value: value.choices[index].itemId,
                      options: captureBag,
                      onChanged: (id) => choice(
                        index,
                        SceneBattleDemonstrationChoice.capture(id),
                      ),
                    ),
                  Row(
                    children: [
                      StudioButton(
                        label: 'Monter',
                        onPressed: index == 0
                            ? null
                            : () => apply(() => draft.moveChoiceUp(index)),
                      ),
                      const SizedBox(width: 8),
                      StudioButton(
                        label: 'Retirer',
                        onPressed: value.choices.length == 1
                            ? null
                            : () => apply(() => draft.removeChoice(index)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                StudioButton(
                  label: 'Ajouter une action',
                  onPressed: value.choices.length >= 100
                      ? null
                      : () => apply(draft.addChoice),
                ),
                StudioToggleRow(
                  label: 'Garantir la capture pendant la démonstration',
                  value: value.captureAlwaysSucceeds,
                  onChanged: (enabled) =>
                      patch({'captureAlwaysSucceeds': enabled}),
                ),
                StudioCommitField(
                  label: 'Temps de lecture entre les actions (ms)',
                  value: '${value.stepDelayMs}',
                  tryCommit: (text) {
                    if (!draft.delay(text)) return false;
                    widget.onChanged(draft.value);
                    return true;
                  },
                ),
              ],
            ],
          );
        },
      );
}
