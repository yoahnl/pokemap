import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

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

  void _patch(Map<String, dynamic> patch) => widget.onChanged(
    SceneBattleDemonstration.fromJson({...widget.value!.toJson(), ...patch}),
  );

  void _choice(int index, SceneBattleDemonstrationChoice choice) => _patch({
    'choices': [
      for (var i = 0; i < widget.value!.choices.length; i++)
        (i == index ? choice : widget.value!.choices[i]).toJson(),
    ],
  });

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
          final teams = {
            for (final trainer in widget.project.trainers)
              if (trainer.team.isNotEmpty &&
                  trainer.team.length <= 6 &&
                  trainer.battleFormat == BattleFormat.singles)
                trainer.id: trainer.name,
          };
          final value = widget.value;
          final available =
              widget.project.settings.dimension == ProjectDimension.threeD &&
              teams.isNotEmpty &&
              captures.isNotEmpty;
          final bag = {
            for (final entry in value?.bagItems ?? const <BagEntry>[])
              entry.itemId: choices[entry.itemId] ?? entry.itemId,
          };
          final captureBag = {
            for (final entry in bag.entries)
              if (captures.containsKey(entry.key)) entry.key: entry.value,
          };
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StudioToggleRow(
                label: 'Démonstration automatique',
                value: value != null,
                description: 'Équipe et sac temporaires. Le joueur retrouve exactement son état après le combat.',
                onChanged: !available && value == null
                    ? null
                    : (enabled) => widget.onChanged(
                        enabled
                            ? SceneBattleDemonstration(
                                playerTrainerId: teams.keys.first,
                                bagItems: [
                                  BagEntry(
                                    itemId: captures.keys.first,
                                    quantity: 20,
                                  ),
                                ],
                                choices: [
                                  SceneBattleDemonstrationChoice.capture(
                                    captures.keys.first,
                                  ),
                                ],
                              )
                            : null,
                      ),
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
                  onChanged: (id) => _patch({'playerTrainerId': id}),
                ),
                const SizedBox(height: 12),
                const Text('Sac temporaire'),
                for (var index = 0; index < value.bagItems.length; index++) ...[
                  StudioSelect(
                    label: 'Objet ${index + 1}',
                    value: value.bagItems[index].itemId,
                    options: {
                      for (final entry in choices.entries)
                        if ((entry.key == value.bagItems[index].itemId ||
                                !bag.containsKey(entry.key)) &&
                            (!value.choices.any(
                                  (action) =>
                                      action.itemId ==
                                      value.bagItems[index].itemId,
                                ) ||
                                captures.containsKey(entry.key)))
                          entry.key: entry.value,
                    },
                    onChanged: (id) => _patch({
                      'bagItems': [
                        for (var i = 0; i < value.bagItems.length; i++)
                          (i == index
                                  ? value.bagItems[i].copyWith(itemId: id)
                                  : value.bagItems[i])
                              .toJson(),
                      ],
                      'choices': [
                        for (final action in value.choices)
                          (action.itemId == value.bagItems[index].itemId
                                  ? SceneBattleDemonstrationChoice.capture(id)
                                  : action)
                              .toJson(),
                      ],
                    }),
                  ),
                  StudioCommitField(
                    label: 'Quantité ${index + 1}',
                    value: '${value.bagItems[index].quantity}',
                    tryCommit: (text) {
                      final quantity = int.tryParse(text);
                      if (quantity == null || quantity < 1 || quantity > 999) {
                        return false;
                      }
                      _patch({
                        'bagItems': [
                          for (var i = 0; i < value.bagItems.length; i++)
                            (i == index
                                    ? value.bagItems[i].copyWith(
                                        quantity: quantity,
                                      )
                                    : value.bagItems[i])
                                .toJson(),
                        ],
                      });
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
                        : () => _patch({
                            'bagItems': [
                              for (var i = 0; i < value.bagItems.length; i++)
                                if (i != index) value.bagItems[i].toJson(),
                            ],
                          }),
                  ),
                ],
                StudioButton(
                  label: 'Ajouter un objet',
                  onPressed: choices.keys.every(bag.containsKey)
                      ? null
                      : () {
                          final id = choices.keys.firstWhere(
                            (id) => !bag.containsKey(id),
                          );
                          _patch({
                            'bagItems': [
                              ...value.bagItems.map((entry) => entry.toJson()),
                              BagEntry(itemId: id, quantity: 1).toJson(),
                            ],
                          });
                        },
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
                    onChanged: (kind) => _choice(
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
                      onChanged: (id) => _choice(
                        index,
                        SceneBattleDemonstrationChoice.fight(int.parse(id)),
                      ),
                    ),
                  if (value.choices[index].kind == 'capture')
                    StudioSelect(
                      label: 'Ball ${index + 1}',
                      value: value.choices[index].itemId,
                      options: captureBag,
                      onChanged: (id) => _choice(
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
                            : () {
                                final actions = [...value.choices];
                                final moved = actions.removeAt(index);
                                actions.insert(index - 1, moved);
                                _patch({
                                  'choices': actions
                                      .map((action) => action.toJson())
                                      .toList(),
                                });
                              },
                      ),
                      const SizedBox(width: 8),
                      StudioButton(
                        label: 'Retirer',
                        onPressed: value.choices.length == 1
                            ? null
                            : () => _patch({
                                'choices': [
                                  for (var i = 0; i < value.choices.length; i++)
                                    if (i != index) value.choices[i].toJson(),
                                ],
                              }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                StudioButton(
                  label: 'Ajouter une action',
                  onPressed: value.choices.length >= 100
                      ? null
                      : () => _patch({
                          'choices': [
                            ...value.choices.map((choice) => choice.toJson()),
                            SceneBattleDemonstrationChoice.fight(0).toJson(),
                          ],
                        }),
                ),
                StudioToggleRow(
                  label: 'Garantir la capture pendant la démonstration',
                  value: value.captureAlwaysSucceeds,
                  onChanged: (enabled) =>
                      _patch({'captureAlwaysSucceeds': enabled}),
                ),
                StudioCommitField(
                  label: 'Temps de lecture entre les actions (ms)',
                  value: '${value.stepDelayMs}',
                  tryCommit: (text) {
                    final delay = int.tryParse(text);
                    if (delay == null || delay < 50 || delay > 10000) {
                      return false;
                    }
                    _patch({'stepDelayMs': delay});
                    return true;
                  },
                ),
              ],
            ],
          );
        },
      );
}
