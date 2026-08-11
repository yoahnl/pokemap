import 'package:map_core/map_core.dart';

final class ShopEditorItemOption {
  const ShopEditorItemOption({
    required this.id,
    required this.label,
    this.definition,
  });

  final String id;
  final String label;
  final ProjectItemDefinition? definition;
}

final class ShopSceneReference {
  const ShopSceneReference({
    required this.sceneId,
    required this.sceneName,
    required this.nodeId,
  });

  final String sceneId;
  final String sceneName;
  final String nodeId;
}

final class ShopDeleteResult {
  const ShopDeleteResult({
    required this.deleted,
    this.references = const <ShopSceneReference>[],
  });

  final bool deleted;
  final List<ShopSceneReference> references;
}

final class ShopEditorValidationException implements Exception {
  const ShopEditorValidationException(this.message);

  final String message;

  @override
  String toString() => 'ShopEditorValidationException: $message';
}

/// Pure application controller for guided shop authoring.
///
/// The UI never asks for technical identifiers: stable shop ids are derived
/// once from the readable label and item ids always come from [itemOptions].
final class ShopEditorController {
  static const String defaultStateId = '__default__';

  ShopEditorController({
    required ProjectManifest manifest,
    required List<ShopEditorItemOption> itemOptions,
  })  : _manifest = manifest,
        itemOptions = List<ShopEditorItemOption>.unmodifiable(itemOptions) {
    final ids = <String>{};
    for (final option in itemOptions) {
      final id = option.id.trim();
      if (id.isEmpty || !ids.add(id)) {
        throw const ShopEditorValidationException(
          'Le catalogue des objets contient un identifiant vide ou dupliqué.',
        );
      }
    }
  }

  ProjectManifest _manifest;
  final List<ShopEditorItemOption> itemOptions;

  ProjectManifest get manifest => _manifest;
  List<ShopDefinition> get shops => _manifest.shops;

  ShopDefinition shopById(String shopId) {
    return shops.firstWhere(
      (shop) => shop.id == shopId,
      orElse: () => throw ShopEditorValidationException(
        'Boutique inconnue : $shopId.',
      ),
    );
  }

  ShopStateDefinition stateById(String shopId, String stateId) {
    if (stateId == defaultStateId) {
      throw const ShopEditorValidationException(
        'L’état par défaut est implicite et ne possède pas de configuration.',
      );
    }
    return shopById(shopId).states.firstWhere(
          (state) => state.id == stateId,
          orElse: () => throw ShopEditorValidationException(
            'État de boutique inconnu : $stateId.',
          ),
        );
  }

  ShopDefinition createShop({required String label}) {
    final normalizedLabel = label.trim();
    if (normalizedLabel.isEmpty) {
      throw const ShopEditorValidationException(
        'Le nom de la boutique est obligatoire.',
      );
    }
    final baseId = _slug(normalizedLabel);
    if (baseId.isEmpty) {
      throw const ShopEditorValidationException(
        'Le nom doit contenir au moins une lettre ou un chiffre.',
      );
    }
    final existingIds = shops.map((shop) => shop.id).toSet();
    var id = baseId;
    var suffix = 2;
    while (existingIds.contains(id)) {
      id = '$baseId-$suffix';
      suffix += 1;
    }
    final shop = ShopDefinition(id: id, label: normalizedLabel);
    _manifest = _manifest.copyWith(shops: <ShopDefinition>[...shops, shop]);
    return shop;
  }

  void renameShop(String shopId, String label) {
    final normalizedLabel = label.trim();
    if (normalizedLabel.isEmpty) {
      throw const ShopEditorValidationException(
        'Le nom de la boutique est obligatoire.',
      );
    }
    _replaceShop(shopId, shopById(shopId).copyWith(label: normalizedLabel));
  }

  void addEntry({
    required String shopId,
    required String itemId,
    required int price,
    int? sellPrice,
    int? stock,
  }) {
    final shop = shopById(shopId);
    final option = itemOptions.where((item) => item.id == itemId).firstOrNull;
    if (option == null) {
      throw const ShopEditorValidationException(
        'Choisissez un objet du catalogue.',
      );
    }
    if (price <= 0) {
      throw const ShopEditorValidationException(
        'Le prix doit être strictement positif.',
      );
    }
    if (stock != null && stock < 0) {
      throw const ShopEditorValidationException(
        'Le stock ne peut pas être négatif.',
      );
    }
    if (sellPrice != null && sellPrice <= 0) {
      throw const ShopEditorValidationException(
        'Le prix de revente doit être strictement positif.',
      );
    }
    if (shop.entries.any((entry) => entry.itemId == itemId)) {
      throw const ShopEditorValidationException(
        'Cet objet est déjà présent dans la boutique.',
      );
    }
    final entry = ShopEntryDefinition(
      itemId: option.id,
      price: price,
      sellPrice: sellPrice,
      stock: stock,
    ).normalized(knownItemIds: _knownItemIds);
    _replaceShop(
      shopId,
      shop.copyWith(entries: <ShopEntryDefinition>[...shop.entries, entry]),
    );
  }

  void updateEntry({
    required String shopId,
    required String itemId,
    required int price,
    int? sellPrice,
    int? stock,
  }) {
    final shop = shopById(shopId);
    final index = shop.entries.indexWhere((entry) => entry.itemId == itemId);
    if (index < 0) {
      throw ShopEditorValidationException('Objet inconnu : $itemId.');
    }
    final updated = ShopEntryDefinition(
      itemId: itemId,
      price: price,
      sellPrice: sellPrice,
      stock: stock,
    ).normalized(knownItemIds: _knownItemIds);
    final entries = <ShopEntryDefinition>[...shop.entries];
    entries[index] = updated;
    _replaceShop(shopId, shop.copyWith(entries: entries));
  }

  void removeEntry({required String shopId, required String itemId}) {
    final shop = shopById(shopId);
    if (!shop.entries.any((entry) => entry.itemId == itemId)) return;
    _replaceShop(
      shopId,
      shop.copyWith(
        entries: shop.entries
            .where((entry) => entry.itemId != itemId)
            .toList(growable: false),
      ),
    );
  }

  ShopStateDefinition createStateFromDefault({
    required String shopId,
    required String label,
    required ScriptCondition activation,
    int priority = 0,
  }) {
    final shop = shopById(shopId);
    return _createState(
      shop: shop,
      label: label,
      activation: activation,
      priority: priority,
      entries: shop.entries,
    );
  }

  ShopStateDefinition createEmptyState({
    required String shopId,
    required String label,
    required ScriptCondition activation,
    int priority = 0,
  }) {
    return _createState(
      shop: shopById(shopId),
      label: label,
      activation: activation,
      priority: priority,
      entries: const <ShopEntryDefinition>[],
    );
  }

  ShopStateDefinition duplicateState({
    required String shopId,
    required String stateId,
  }) {
    final shop = shopById(shopId);
    final source = stateById(shopId, stateId);
    final state = source.copyWith(
      id: _uniqueStateId(shop, source.label),
      label: '${source.label} (copie)',
    );
    _replaceShop(
      shopId,
      shop.copyWith(states: <ShopStateDefinition>[...shop.states, state]),
    );
    return state;
  }

  void renameState({
    required String shopId,
    required String stateId,
    required String label,
  }) {
    final normalizedLabel = label.trim();
    if (normalizedLabel.isEmpty) {
      throw const ShopEditorValidationException(
        'Le nom de l’état est obligatoire.',
      );
    }
    _replaceState(
      shopId,
      stateId,
      stateById(shopId, stateId).copyWith(label: normalizedLabel),
    );
  }

  void updateStateSettings({
    required String shopId,
    required String stateId,
    required int priority,
    required bool isOpen,
    String? storefrontLabel,
    required String welcomeMessage,
    required String closedMessage,
  }) {
    _replaceState(
      shopId,
      stateId,
      stateById(shopId, stateId).copyWith(
        priority: priority,
        isOpen: isOpen,
        storefrontLabel: storefrontLabel,
        welcomeMessage: welcomeMessage,
        closedMessage: closedMessage,
      ),
    );
  }

  void replaceStateActivation({
    required String shopId,
    required String stateId,
    required ScriptCondition activation,
  }) {
    _replaceState(
      shopId,
      stateId,
      stateById(shopId, stateId).copyWith(activation: activation),
    );
  }

  void addStateEntry({
    required String shopId,
    required String stateId,
    required String itemId,
    required int price,
    int? sellPrice,
    int? stock,
  }) {
    final state = stateById(shopId, stateId);
    if (state.entries.any((entry) => entry.itemId == itemId)) {
      throw const ShopEditorValidationException(
        'Cet objet est déjà présent dans cet état.',
      );
    }
    final entry = _validatedEntry(
      itemId: itemId,
      price: price,
      sellPrice: sellPrice,
      stock: stock,
    );
    _replaceState(
      shopId,
      stateId,
      state.copyWith(
        entries: <ShopEntryDefinition>[...state.entries, entry],
      ),
    );
  }

  void updateStateEntry({
    required String shopId,
    required String stateId,
    required String itemId,
    required int price,
    int? sellPrice,
    int? stock,
  }) {
    final state = stateById(shopId, stateId);
    final index = state.entries.indexWhere((entry) => entry.itemId == itemId);
    if (index < 0) {
      throw ShopEditorValidationException('Objet inconnu : $itemId.');
    }
    final entries = <ShopEntryDefinition>[...state.entries];
    entries[index] = _validatedEntry(
      itemId: itemId,
      price: price,
      sellPrice: sellPrice,
      stock: stock,
    );
    _replaceState(shopId, stateId, state.copyWith(entries: entries));
  }

  void removeStateEntry({
    required String shopId,
    required String stateId,
    required String itemId,
  }) {
    final state = stateById(shopId, stateId);
    if (!state.entries.any((entry) => entry.itemId == itemId)) return;
    _replaceState(
      shopId,
      stateId,
      state.copyWith(
        entries: state.entries
            .where((entry) => entry.itemId != itemId)
            .toList(growable: false),
      ),
    );
  }

  void deleteState({required String shopId, required String stateId}) {
    if (stateId == defaultStateId) {
      throw const ShopEditorValidationException(
        'L’état par défaut ne peut pas être supprimé.',
      );
    }
    final shop = shopById(shopId);
    stateById(shopId, stateId);
    _replaceShop(
      shopId,
      shop.copyWith(
        states: shop.states
            .where((state) => state.id != stateId)
            .toList(growable: false),
      ),
    );
  }

  List<ShopSceneReference> referencesFor(String shopId) {
    final references = <ShopSceneReference>[];
    for (final scene in _manifest.scenes) {
      for (final node in scene.graph.nodes) {
        final payload = node.payload;
        if (payload is! SceneActionPayload) continue;
        final command = payload.interactiveCommand;
        if (command is SceneOpenShopInteractiveCommand &&
            command.shopId == shopId) {
          references.add(
            ShopSceneReference(
              sceneId: scene.id,
              sceneName: scene.name,
              nodeId: node.id,
            ),
          );
        }
      }
    }
    return List<ShopSceneReference>.unmodifiable(references);
  }

  ShopDeleteResult deleteShop(
    String shopId, {
    String? replacementShopId,
  }) {
    shopById(shopId);
    final references = referencesFor(shopId);
    if (references.isNotEmpty && replacementShopId == null) {
      return ShopDeleteResult(deleted: false, references: references);
    }
    var scenes = _manifest.scenes;
    if (references.isNotEmpty) {
      final replacement = shopById(replacementShopId!);
      if (replacement.id == shopId) {
        throw const ShopEditorValidationException(
          'La boutique de remplacement doit être différente.',
        );
      }
      scenes = scenes
          .map(
            (scene) => _replaceSceneShopReference(
              scene,
              fromShopId: shopId,
              toShopId: replacement.id,
            ),
          )
          .toList(growable: false);
    }
    _manifest = _manifest.copyWith(
      scenes: scenes,
      shops: shops.where((shop) => shop.id != shopId).toList(growable: false),
    );
    return ShopDeleteResult(deleted: true, references: references);
  }

  Set<String> get _knownItemIds => itemOptions.map((item) => item.id).toSet();

  ShopStateDefinition _createState({
    required ShopDefinition shop,
    required String label,
    required ScriptCondition activation,
    required int priority,
    required List<ShopEntryDefinition> entries,
  }) {
    final normalizedLabel = label.trim();
    if (normalizedLabel.isEmpty) {
      throw const ShopEditorValidationException(
        'Le nom de l’état est obligatoire.',
      );
    }
    final state = ShopStateDefinition(
      id: _uniqueStateId(shop, normalizedLabel),
      label: normalizedLabel,
      priority: priority,
      activation: activation,
      entries: List<ShopEntryDefinition>.of(entries),
    ).normalized(knownItemIds: _knownItemIds);
    _replaceShop(
      shop.id,
      shop.copyWith(states: <ShopStateDefinition>[...shop.states, state]),
    );
    return state;
  }

  String _uniqueStateId(ShopDefinition shop, String label) {
    final baseId = _slug(label);
    if (baseId.isEmpty) {
      throw const ShopEditorValidationException(
        'Le nom doit contenir au moins une lettre ou un chiffre.',
      );
    }
    final existingIds = shop.states.map((state) => state.id).toSet();
    var id = baseId;
    var suffix = 2;
    while (existingIds.contains(id)) {
      id = '$baseId-$suffix';
      suffix += 1;
    }
    return id;
  }

  ShopEntryDefinition _validatedEntry({
    required String itemId,
    required int price,
    required int? sellPrice,
    required int? stock,
  }) {
    if (!itemOptions.any((item) => item.id == itemId)) {
      throw const ShopEditorValidationException(
        'Choisissez un objet du catalogue.',
      );
    }
    if (price <= 0) {
      throw const ShopEditorValidationException(
        'Le prix doit être strictement positif.',
      );
    }
    if (stock != null && stock < 0) {
      throw const ShopEditorValidationException(
        'Le stock ne peut pas être négatif.',
      );
    }
    if (sellPrice != null && sellPrice <= 0) {
      throw const ShopEditorValidationException(
        'Le prix de revente doit être strictement positif.',
      );
    }
    return ShopEntryDefinition(
      itemId: itemId,
      price: price,
      sellPrice: sellPrice,
      stock: stock,
    ).normalized(knownItemIds: _knownItemIds);
  }

  void _replaceState(
    String shopId,
    String stateId,
    ShopStateDefinition replacement,
  ) {
    final shop = shopById(shopId);
    final index = shop.states.indexWhere((state) => state.id == stateId);
    if (index < 0) {
      throw ShopEditorValidationException(
        'État de boutique inconnu : $stateId.',
      );
    }
    final states = <ShopStateDefinition>[...shop.states];
    states[index] = replacement;
    _replaceShop(shopId, shop.copyWith(states: states));
  }

  void _replaceShop(String shopId, ShopDefinition replacement) {
    final index = shops.indexWhere((shop) => shop.id == shopId);
    if (index < 0) {
      throw ShopEditorValidationException('Boutique inconnue : $shopId.');
    }
    final next = <ShopDefinition>[...shops];
    next[index] = replacement.normalized(knownItemIds: _knownItemIds);
    _manifest = _manifest.copyWith(shops: next);
  }
}

SceneAsset _replaceSceneShopReference(
  SceneAsset scene, {
  required String fromShopId,
  required String toShopId,
}) {
  var changed = false;
  final nodes = scene.graph.nodes.map((node) {
    final payload = node.payload;
    if (payload is! SceneActionPayload) return node;
    final command = payload.interactiveCommand;
    if (command is! SceneOpenShopInteractiveCommand ||
        command.shopId != fromShopId) {
      return node;
    }
    changed = true;
    return SceneNode(
      id: node.id,
      kind: node.kind,
      title: node.title,
      description: node.description,
      payload: SceneActionPayload.interactive(
        SceneInteractiveCommand.openShop(shopId: toShopId),
        actionKind: payload.actionKind,
        parameters: payload.parameters,
      ),
    );
  }).toList(growable: false);
  if (!changed) return scene;
  return SceneAsset(
    id: scene.id,
    name: scene.name,
    description: scene.description,
    storylineId: scene.storylineId,
    chapterId: scene.chapterId,
    tags: scene.tags,
    graph: SceneGraph(
      startNodeId: scene.graph.startNodeId,
      nodes: nodes,
      edges: scene.graph.edges,
    ),
    layout: scene.layout,
    declaredOutcomes: scene.declaredOutcomes,
    metadata: scene.metadata,
  );
}

String _slug(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');
