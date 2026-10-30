import 'gameplay_calendar.dart';

const maximumDeferredCraftingQuantity = 9007199254740991;

final class DeferredCraftingRecipe {
  DeferredCraftingRecipe({
    required this.recipeId,
    required this.label,
    required this.inputItemId,
    required this.inputQuantity,
    required this.outputItemId,
    required this.outputQuantity,
  }) {
    _identity(recipeId);
    _identity(label);
    _identity(inputItemId);
    _identity(outputItemId);
    _positive(inputQuantity);
    _positive(outputQuantity);
  }

  factory DeferredCraftingRecipe.fromJson(Map<String, dynamic> json) {
    _fields(json, {
      'recipeId',
      'label',
      'inputItemId',
      'inputQuantity',
      'outputItemId',
      'outputQuantity',
    });
    return DeferredCraftingRecipe(
      recipeId: _string(json, 'recipeId'),
      label: _string(json, 'label'),
      inputItemId: _string(json, 'inputItemId'),
      inputQuantity: _integer(json, 'inputQuantity'),
      outputItemId: _string(json, 'outputItemId'),
      outputQuantity: _integer(json, 'outputQuantity'),
    );
  }

  final String recipeId, label, inputItemId, outputItemId;
  final int inputQuantity, outputQuantity;

  Map<String, dynamic> toJson() => {
    'recipeId': recipeId,
    'label': label,
    'inputItemId': inputItemId,
    'inputQuantity': inputQuantity,
    'outputItemId': outputItemId,
    'outputQuantity': outputQuantity,
  };

  @override
  bool operator ==(Object other) =>
      other is DeferredCraftingRecipe &&
      recipeId == other.recipeId &&
      label == other.label &&
      inputItemId == other.inputItemId &&
      inputQuantity == other.inputQuantity &&
      outputItemId == other.outputItemId &&
      outputQuantity == other.outputQuantity;

  @override
  int get hashCode => Object.hash(
    recipeId,
    label,
    inputItemId,
    inputQuantity,
    outputItemId,
    outputQuantity,
  );
}

final class DeferredCraftingDefinition {
  DeferredCraftingDefinition({
    required this.serviceId,
    required this.label,
    required Iterable<DeferredCraftingRecipe> recipes,
    this.maximumBatchQuantity = 99,
    this.requiredDayChanges = 1,
  }) : recipes = List.unmodifiable(recipes) {
    _identity(serviceId);
    _identity(label);
    _positive(maximumBatchQuantity);
    _positive(requiredDayChanges);
    if (this.recipes.isEmpty ||
        this.recipes.map((recipe) => recipe.recipeId).toSet().length !=
            this.recipes.length) {
      throw const FormatException('Crafting requires unique nonempty recipes.');
    }
  }

  factory DeferredCraftingDefinition.fromJson(Map<String, dynamic> json) {
    _fields(json, {
      'schemaVersion',
      'serviceId',
      'label',
      'recipes',
      'maximumBatchQuantity',
      'requiredDayChanges',
    });
    _version(json);
    final recipes = json['recipes'];
    if (recipes is! List) {
      throw const FormatException('Crafting recipes must be a list.');
    }
    return DeferredCraftingDefinition(
      serviceId: _string(json, 'serviceId'),
      label: _string(json, 'label'),
      recipes: recipes.map(
        (value) => DeferredCraftingRecipe.fromJson(_object(value)),
      ),
      maximumBatchQuantity: _integer(json, 'maximumBatchQuantity'),
      requiredDayChanges: _integer(json, 'requiredDayChanges'),
    );
  }

  final String serviceId, label;
  final List<DeferredCraftingRecipe> recipes;
  final int maximumBatchQuantity, requiredDayChanges;

  DeferredCraftingRecipe? recipeFor(String recipeId) {
    for (final recipe in recipes) {
      if (recipe.recipeId == recipeId) return recipe;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'serviceId': serviceId,
    'label': label,
    'recipes': [for (final recipe in recipes) recipe.toJson()],
    'maximumBatchQuantity': maximumBatchQuantity,
    'requiredDayChanges': requiredDayChanges,
  };

  @override
  bool operator ==(Object other) =>
      other is DeferredCraftingDefinition &&
      serviceId == other.serviceId &&
      label == other.label &&
      recipes.length == other.recipes.length &&
      Iterable.generate(
        recipes.length,
      ).every((index) => recipes[index] == other.recipes[index]) &&
      maximumBatchQuantity == other.maximumBatchQuantity &&
      requiredDayChanges == other.requiredDayChanges;

  @override
  int get hashCode => Object.hash(
    serviceId,
    label,
    Object.hashAll(recipes),
    maximumBatchQuantity,
    requiredDayChanges,
  );
}

final class DeferredCraftingOrder {
  DeferredCraftingOrder({
    required this.orderId,
    required this.recipeId,
    required this.inputItemId,
    required this.inputQuantity,
    required this.outputItemId,
    required this.outputQuantity,
    required this.submittedDayRevision,
    required this.requiredDayChanges,
  }) {
    _identity(orderId);
    _identity(recipeId);
    _identity(inputItemId);
    _identity(outputItemId);
    _positive(inputQuantity);
    _positive(outputQuantity);
    _positive(requiredDayChanges);
    _revision(submittedDayRevision);
    if (submittedDayRevision >
        GameplayCalendarState.maximumRevision - requiredDayChanges) {
      throw const FormatException(
        'Crafting completion exceeds the calendar revision range.',
      );
    }
  }

  factory DeferredCraftingOrder.fromJson(Map<String, dynamic> json) {
    _fields(json, {
      'schemaVersion',
      'orderId',
      'recipeId',
      'inputItemId',
      'inputQuantity',
      'outputItemId',
      'outputQuantity',
      'submittedDayRevision',
      'requiredDayChanges',
    });
    _version(json);
    return DeferredCraftingOrder(
      orderId: _string(json, 'orderId'),
      recipeId: _string(json, 'recipeId'),
      inputItemId: _string(json, 'inputItemId'),
      inputQuantity: _integer(json, 'inputQuantity'),
      outputItemId: _string(json, 'outputItemId'),
      outputQuantity: _integer(json, 'outputQuantity'),
      submittedDayRevision: _integer(json, 'submittedDayRevision'),
      requiredDayChanges: _integer(json, 'requiredDayChanges'),
    );
  }

  final String orderId, recipeId, inputItemId, outputItemId;
  final int inputQuantity,
      outputQuantity,
      submittedDayRevision,
      requiredDayChanges;

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'orderId': orderId,
    'recipeId': recipeId,
    'inputItemId': inputItemId,
    'inputQuantity': inputQuantity,
    'outputItemId': outputItemId,
    'outputQuantity': outputQuantity,
    'submittedDayRevision': submittedDayRevision,
    'requiredDayChanges': requiredDayChanges,
  };

  @override
  bool operator ==(Object other) =>
      other is DeferredCraftingOrder &&
      orderId == other.orderId &&
      recipeId == other.recipeId &&
      inputItemId == other.inputItemId &&
      inputQuantity == other.inputQuantity &&
      outputItemId == other.outputItemId &&
      outputQuantity == other.outputQuantity &&
      submittedDayRevision == other.submittedDayRevision &&
      requiredDayChanges == other.requiredDayChanges;

  @override
  int get hashCode => Object.hash(
    orderId,
    recipeId,
    inputItemId,
    inputQuantity,
    outputItemId,
    outputQuantity,
    submittedDayRevision,
    requiredDayChanges,
  );
}

final class DeferredCraftingServiceState {
  const DeferredCraftingServiceState.empty()
    : revision = 0,
      pendingOrder = null;

  DeferredCraftingServiceState({required this.revision, this.pendingOrder}) {
    _revision(revision);
    if (pendingOrder != null && revision == 0) {
      throw const FormatException(
        'A pending crafting order requires a service revision.',
      );
    }
  }

  factory DeferredCraftingServiceState.fromJson(Map<String, dynamic> json) {
    _fields(json, {
      'revision',
      if (json.containsKey('pendingOrder')) 'pendingOrder',
    });
    return DeferredCraftingServiceState(
      revision: _integer(json, 'revision'),
      pendingOrder: json.containsKey('pendingOrder')
          ? DeferredCraftingOrder.fromJson(_object(json['pendingOrder']))
          : null,
    );
  }

  final int revision;
  final DeferredCraftingOrder? pendingOrder;

  Map<String, dynamic> toJson() => {
    'revision': revision,
    if (pendingOrder != null) 'pendingOrder': pendingOrder!.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is DeferredCraftingServiceState &&
      revision == other.revision &&
      pendingOrder == other.pendingOrder;

  @override
  int get hashCode => Object.hash(revision, pendingOrder);
}

final class DeferredCraftingState {
  const DeferredCraftingState.empty() : servicesById = const {};

  DeferredCraftingState({
    required Map<String, DeferredCraftingServiceState> servicesById,
  }) : servicesById = Map.unmodifiable(servicesById) {
    for (final serviceId in servicesById.keys) {
      _identity(serviceId);
    }
  }

  factory DeferredCraftingState.fromJson(Map<String, dynamic> json) {
    _fields(json, {'schemaVersion', 'servicesById'});
    _version(json);
    final services = _object(json['servicesById']);
    return DeferredCraftingState(
      servicesById: {
        for (final entry in services.entries)
          entry.key: DeferredCraftingServiceState.fromJson(
            _object(entry.value),
          ),
      },
    );
  }

  final Map<String, DeferredCraftingServiceState> servicesById;

  DeferredCraftingServiceState serviceFor(String serviceId) =>
      servicesById[serviceId] ?? const DeferredCraftingServiceState.empty();

  DeferredCraftingState withService(
    String serviceId,
    DeferredCraftingServiceState service,
  ) => DeferredCraftingState(
    servicesById: {...servicesById, serviceId: service},
  );

  void validateCalendar(GameplayCalendarState calendar) {
    for (final service in servicesById.values) {
      final order = service.pendingOrder;
      if (order != null &&
          (!calendar.isInitialized ||
              order.submittedDayRevision > calendar.dayRevision)) {
        throw const FormatException(
          'Crafting order and gameplay calendar are inconsistent.',
        );
      }
    }
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'servicesById': {
      for (final entry in servicesById.entries) entry.key: entry.value.toJson(),
    },
  };

  @override
  bool operator ==(Object other) =>
      other is DeferredCraftingState &&
      servicesById.length == other.servicesById.length &&
      servicesById.entries.every(
        (entry) => other.servicesById[entry.key] == entry.value,
      );

  @override
  int get hashCode => Object.hashAllUnordered(
    servicesById.entries.map((entry) => Object.hash(entry.key, entry.value)),
  );
}

Object? readDeferredCraftingStateJson(Map<dynamic, dynamic> json, String key) {
  if (json.containsKey(key) && json[key] == null) {
    throw const FormatException('Deferred crafting state must not be null.');
  }
  return json[key];
}

void _fields(Map<String, dynamic> json, Set<String> fields) {
  if (json.length != fields.length || !json.keys.toSet().containsAll(fields)) {
    throw const FormatException('Invalid deferred crafting fields.');
  }
}

void _version(Map<String, dynamic> json) {
  if (json['schemaVersion'] is! int || json['schemaVersion'] != 1) {
    throw const FormatException('Unsupported deferred crafting schema.');
  }
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw const FormatException('Crafting requires a JSON object.');
  }
  return Map<String, dynamic>.from(value);
}

String _string(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('Crafting $key must be a string.');
  }
  return value;
}

int _integer(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('Crafting $key must be an integer.');
  return value;
}

void _identity(String value) {
  if (value.isEmpty || value.trim() != value) {
    throw const FormatException(
      'Crafting identities and labels must be nonempty and trim-exact.',
    );
  }
}

void _positive(int value) {
  if (value < 1 || value > maximumDeferredCraftingQuantity) {
    throw const FormatException(
      'Crafting quantities must be positive exact JSON integers.',
    );
  }
}

void _revision(int value) {
  if (value < 0 || value > GameplayCalendarState.maximumRevision) {
    throw const FormatException('Invalid crafting revision.');
  }
}
