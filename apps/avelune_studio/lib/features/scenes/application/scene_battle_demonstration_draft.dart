import 'package:map_core/map_core_domain.dart';

class SceneBattleDemonstrationDraft {
  SceneBattleDemonstrationDraft({
    required this.project,
    required this.value,
    this.items = const {},
    this.captureItems = const {},
  });

  final ProjectManifest project;
  SceneBattleDemonstration? value;
  final Map<String, String> items, captureItems;

  Map<String, String> get teams => {
    for (final trainer in project.trainers)
      if (trainer.team.isNotEmpty &&
          trainer.team.length <= 6 &&
          trainer.battleFormat == BattleFormat.singles)
        trainer.id: trainer.name,
  };
  bool get available =>
      project.settings.dimension == ProjectDimension.threeD &&
      teams.isNotEmpty &&
      captureItems.isNotEmpty;
  Map<String, String> get bag => {
    for (final entry in value?.bagItems ?? const <BagEntry>[])
      entry.itemId: items[entry.itemId] ?? entry.itemId,
  };
  Map<String, String> get captureBag => {
    for (final entry in bag.entries)
      if (captureItems.containsKey(entry.key)) entry.key: entry.value,
  };
  Map<String, String> replacementItems(int index) => {
    for (final entry in items.entries)
      if ((entry.key == value!.bagItems[index].itemId ||
              !bag.containsKey(entry.key)) &&
          (!value!.choices.any(
                (action) => action.itemId == value!.bagItems[index].itemId,
              ) ||
              captureItems.containsKey(entry.key)))
        entry.key: entry.value,
  };

  void enable(bool enabled) {
    if (!enabled) {
      value = null;
    } else if (available) {
      value = SceneBattleDemonstration(
        playerTrainerId: teams.keys.first,
        bagItems: [BagEntry(itemId: captureItems.keys.first, quantity: 20)],
        choices: [
          SceneBattleDemonstrationChoice.capture(captureItems.keys.first),
        ],
      );
    }
  }

  void patch(Map<String, dynamic> values) => value =
      SceneBattleDemonstration.fromJson({...value!.toJson(), ...values});

  void replaceItem(int index, String id) => patch({
    'bagItems': [
      for (var i = 0; i < value!.bagItems.length; i++)
        (i == index
                ? value!.bagItems[i].copyWith(itemId: id)
                : value!.bagItems[i])
            .toJson(),
    ],
    'choices': [
      for (final action in value!.choices)
        (action.itemId == value!.bagItems[index].itemId
                ? SceneBattleDemonstrationChoice.capture(id)
                : action)
            .toJson(),
    ],
  });

  bool quantity(int index, String text) {
    final quantity = int.tryParse(text);
    if (quantity == null || quantity < 1 || quantity > 999) return false;
    patch({
      'bagItems': [
        for (var i = 0; i < value!.bagItems.length; i++)
          (i == index
                  ? value!.bagItems[i].copyWith(quantity: quantity)
                  : value!.bagItems[i])
              .toJson(),
      ],
    });
    return true;
  }

  void removeItem(int index) {
    if (value!.choices.any(
      (choice) => choice.itemId == value!.bagItems[index].itemId,
    )) {
      return;
    }
    patch({
      'bagItems': [
        for (var i = 0; i < value!.bagItems.length; i++)
          if (i != index) value!.bagItems[i].toJson(),
      ],
    });
  }

  void addItem() {
    final id = items.keys.where((id) => !bag.containsKey(id)).firstOrNull;
    if (id == null) return;
    patch({
      'bagItems': [
        ...value!.bagItems.map((item) => item.toJson()),
        BagEntry(itemId: id, quantity: 1).toJson(),
      ],
    });
  }

  void choice(int index, SceneBattleDemonstrationChoice choice) => patch({
    'choices': [
      for (var i = 0; i < value!.choices.length; i++)
        (i == index ? choice : value!.choices[i]).toJson(),
    ],
  });

  void moveChoiceUp(int index) {
    if (index == 0) return;
    final choices = [...value!.choices];
    choices.insert(index - 1, choices.removeAt(index));
    patch({'choices': choices.map((choice) => choice.toJson()).toList()});
  }

  void removeChoice(int index) {
    if (value!.choices.length == 1) return;
    patch({
      'choices': [
        for (var i = 0; i < value!.choices.length; i++)
          if (i != index) value!.choices[i].toJson(),
      ],
    });
  }

  void addChoice() {
    if (value!.choices.length >= 100) return;
    patch({
      'choices': [
        ...value!.choices.map((choice) => choice.toJson()),
        SceneBattleDemonstrationChoice.fight(0).toJson(),
      ],
    });
  }

  bool delay(String text) {
    final delay = int.tryParse(text);
    if (delay == null || delay < 50 || delay > 10000) return false;
    patch({'stepDelayMs': delay});
    return true;
  }
}
