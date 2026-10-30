part of 'runtime_companion_presentation_codec.dart';

abstract final class _RuntimeWorldServiceCompanionCodec {
  static Map<String, dynamic> _map(Object? value) =>
      RuntimeCompanionPresentationCodec.normalizeMap(value);

  static Map<String, Object?> encode(RuntimeWorldServiceSnapshot value) => {
    'revision': value.revision,
    'stage': value.stage.name,
    'request': _request(value.request),
    'content': _content(value.content),
    'safeMessage': value.safeMessage,
    'logicalSelectionId': value.logicalSelectionId,
    'actions': [
      for (final action in value.actions)
        {
          'action': action.action.name,
          'enabled': action.isEnabled,
          'reason': action.unavailableReason,
        },
    ],
  };

  static RuntimeWorldServiceSnapshot decode(Map<String, dynamic> data) {
    final request = _decodeRequest(_map(data['request']));
    final content = data['content'] == null ? null : _decodeContent(_map(data['content']));
    final compatible = switch (request.kind) {
      RuntimeWorldServiceKind.imagePuzzle => content is RuntimeImagePuzzleServiceContent && request is OpenImagePuzzleService && content.progress.definition == request.definition,
      RuntimeWorldServiceKind.crafting => content is RuntimeCraftingServiceContent,
      RuntimeWorldServiceKind.shop => content == null || content is RuntimeShopServiceContent,
      RuntimeWorldServiceKind.heal => content == null || content is RuntimeHealServiceContent,
      RuntimeWorldServiceKind.pc => content == null || content is RuntimePcServiceContent,
      RuntimeWorldServiceKind.partyTrade => content == null || content is RuntimePartyTradeServiceContent,
      RuntimeWorldServiceKind.pokemonGift => content is SceneInteractionRequest &&
          request is OpenPokemonGiftInteractionService && content == request.interaction,
      _ => false,
    };
    if (!compatible) {
      throw const FormatException('The world-service request and content do not match.');
    }
    final revision = data['revision'];
    if (revision is! int || revision < 0) {
      throw const FormatException('Invalid world-service revision.');
    }
    return RuntimeWorldServiceSnapshot(
      revision: revision,
      request: request,
      stage: RuntimeWorldServiceStage.values.byName(data['stage'] as String),
      content: content,
      safeMessage: data['safeMessage'] as String?,
      logicalSelectionId: data['logicalSelectionId'] as String?,
      actions: [
        for (final raw in data['actions'] as List) _availability(_map(raw)),
      ],
    );
  }

  static RuntimeWorldServiceActionAvailability _availability(
    Map<String, dynamic> data,
  ) {
    final action = RuntimeWorldServiceAction.values.byName(
      data['action'] as String,
    );
    return data['enabled'] == true
        ? RuntimeWorldServiceActionAvailability.enabled(action)
        : RuntimeWorldServiceActionAvailability.disabled(
            action,
            reason: data['reason'] as String,
          );
  }

  static Map<String, Object?> _request(RuntimeWorldServiceRequest request) => {
    'kind': request.kind.name,
    'interactionId': request.interactionId,
    'requiredCapabilities': request.requiredCapabilities.toList(),
    'availabilityCondition': request.availabilityCondition?.toJson(),
    ...switch (request) {
      OpenImagePuzzleService() => {'definition': request.definition.toJson()},
      OpenCraftingService() => {'definition': request.definition.toJson()},
      OpenShopService() => {'shopId': request.shopId},
      OpenPcService() => {'storageId': request.storageId},
      OpenHealService() => {
        'requiresConfirmation': request.requiresConfirmation,
        'displayEntityId': request.displayEntityId,
      },
      OpenPartyTradeService(:final npcOffer) => {
        if (npcOffer != null) 'npcOffer': npcOffer.toJson(),
      },
      OpenPokemonGiftInteractionService() => {
        'interaction': request.interaction.toJson(),
        'stage': request.stage.name,
        'pokemon': request.pokemon.toJson(),
        'projectedState': request.projectedState.toJson(),
        'isNewPokedexEntry': request.isNewPokedexEntry,
        'speciesName': request.speciesName,
        'pokedexDetail': request.pokedexDetail == null
            ? null
            : RuntimeCompanionPresentationCodec.encodeRuntimePlayerPauseDetailSnapshot(
                request.pokedexDetail!,
              ),
      },
      _ => throw const FormatException('Unsupported companion world service.'),
    },
  };

  static RuntimeWorldServiceRequest _decodeRequest(Map<String, dynamic> data) {
    final id = data['interactionId'] as String;
    if (id.trim().isEmpty) {
      throw const FormatException('Missing world-service interaction.');
    }
    final capabilities = (data['requiredCapabilities'] as List)
        .cast<String>()
        .toSet();
    final condition = data['availabilityCondition'] == null
        ? null
        : ScriptCondition.fromJson(_map(data['availabilityCondition']));
    return switch (RuntimeWorldServiceKind.values.byName(
      data['kind'] as String,
    )) {
      RuntimeWorldServiceKind.imagePuzzle => OpenImagePuzzleService(interactionId: id, definition: ImagePuzzleDefinition.fromJson(_map(data['definition'])), requiredCapabilities: capabilities, availabilityCondition: condition),
      RuntimeWorldServiceKind.crafting => OpenCraftingService(interactionId: id, definition: DeferredCraftingDefinition.fromJson(_map(data['definition'])), requiredCapabilities: capabilities, availabilityCondition: condition),
      RuntimeWorldServiceKind.shop => OpenShopService(
        interactionId: id,
        shopId: data['shopId'] as String,
        requiredCapabilities: capabilities,
        availabilityCondition: condition,
      ),
      RuntimeWorldServiceKind.pc => OpenPcService(
        interactionId: id,
        storageId: data['storageId'] as String?,
        requiredCapabilities: capabilities,
        availabilityCondition: condition,
      ),
      RuntimeWorldServiceKind.heal => OpenHealService(
        interactionId: id,
        requiresConfirmation: data['requiresConfirmation'] as bool,
        displayEntityId: data['displayEntityId'] as String?,
        requiredCapabilities: capabilities,
        availabilityCondition: condition,
      ),
      RuntimeWorldServiceKind.partyTrade => OpenPartyTradeService(
        interactionId: id,
        npcOffer: data['npcOffer'] == null ? null : NpcPokemonTradeOffer.fromJson(_map(data['npcOffer'])),
        requiredCapabilities: capabilities,
        availabilityCondition: condition,
      ),
      RuntimeWorldServiceKind.pokemonGift => OpenPokemonGiftInteractionService(
        interactionId: id,
        interaction: SceneInteractionRequest.fromJson(
          _map(data['interaction']),
        ),
        stage: PokemonGiftInteractionStage.values.byName(
          data['stage'] as String,
        ),
        pokemon: PlayerPokemon.fromJson(_map(data['pokemon'])),
        projectedState: GameState.fromJson(_map(data['projectedState'])),
        isNewPokedexEntry: data['isNewPokedexEntry'] as bool,
        speciesName: data['speciesName'] as String?,
        pokedexDetail: data['pokedexDetail'] == null
            ? null
            : RuntimeCompanionPresentationCodec.decodeRuntimePlayerPauseDetailSnapshot(
                _map(data['pokedexDetail']),
              ),
      ),
      _ => throw const FormatException('Unsupported companion world service.'),
    };
  }

  static Map<String, Object?>? _content(Object? content) => switch (content) {
    null => null,
    SceneInteractionRequest() => {
      'kind': 'interaction',
      'request': content.toJson(),
    },
    RuntimeShopServiceContent() => {
      'kind': 'shop',
      'title': content.title,
      'message': content.message,
      'money': content.money,
      'mode': content.mode.name,
      'selectedItemId': content.selectedItemId,
      'quantity': content.quantity,
      'totalPrice': content.totalPrice,
      'entries': [
        for (final entry in content.entries)
          {
            'itemId': entry.itemId,
            'label': entry.label,
            'unitPrice': entry.unitPrice,
            'remainingStock': entry.remainingStock,
            'ownedQuantity': entry.ownedQuantity,
            'canTransact': entry.canTransact,
            'unavailableReason': entry.unavailableReason,
          },
      ],
    },
    RuntimeHealServiceContent() => {
      'kind': 'heal',
      'title': content.title,
      'message': content.message,
      'wasHealed': content.wasHealed,
      'display': content.display == null
          ? null
          : {
              'mapId': content.display!.mapId,
              'entityId': content.display!.entityId,
              'memberCount': content.display!.memberCount,
            },
      'members': [
        for (final member in content.members)
          {
            'partyIndex': member.partyIndex,
            'label': member.label,
            'currentHp': member.currentHp,
            'maxHp': member.maxHp,
            'hasStatus': member.hasStatus,
            'depletedMoveCount': member.depletedMoveCount,
          },
      ],
    },
    RuntimePcServiceContent() => {
      'kind': 'pc',
      'title': content.title,
      'message': content.message,
      'selectedBoxId': content.selectedBoxId,
      'boxes': [
        for (final box in content.boxes)
          {
            'boxId': box.boxId,
            'label': box.label,
            'count': box.count,
            'capacity': box.capacity,
          },
      ],
      'party': content.party.map(_pokemon).toList(),
      'stored': content.stored.map(_pokemon).toList(),
    },
    RuntimeImagePuzzleServiceContent() => {'kind': 'imagePuzzle', 'progress': content.progress.toJson(), 'bytes': base64Encode(content.bitmap.bytes), 'width': content.bitmap.width, 'height': content.bitmap.height, 'selectedPieceId': content.selectedPieceId, 'message': content.message},
    RuntimeCraftingServiceContent() => {
      'kind': 'crafting', 'title': content.title, 'status': content.status.name,
      'quantity': content.quantity, 'maximumQuantity': content.maximumQuantity, 'reviewing': content.reviewing,
      'selectedRecipeId': content.selectedRecipeId, 'message': content.message,
      'pendingOutputLabel': content.pendingOutputLabel, 'pendingOutputQuantity': content.pendingOutputQuantity,
      'recipes': [for (final recipe in content.recipes) {'recipeId': recipe.recipeId, 'label': recipe.label,
        'inputLabel': recipe.inputLabel, 'outputLabel': recipe.outputLabel, 'inputQuantity': recipe.inputQuantity,
        'outputQuantity': recipe.outputQuantity, 'ownedQuantity': recipe.ownedQuantity}],
    },
    RuntimePartyTradeServiceContent() => {
      'kind': 'partyTrade',
      'phase': content.phase.name,
      'firstIndividualId': content.firstIndividualId,
      'partnerIndividualId': content.partnerIndividualId,
      'completionMessage': content.completionMessage,
      'members': [
        for (final member in content.members)
          {
            'individualId': member.individualId,
            'speciesId': member.speciesId,
            'label': member.label,
            'level': member.level,
          },
      ],
    },
    _ => throw const FormatException('Unsupported companion service content.'),
  };

  static Object _decodeContent(
    Map<String, dynamic> data,
  ) => switch (data['kind']) {
    'interaction' => SceneInteractionRequest.fromJson(_map(data['request'])),
    'shop' => RuntimeShopServiceContent(
      title: data['title'] as String,
      message: data['message'] as String,
      money: data['money'] as int,
      mode: RuntimeShopMode.values.byName(data['mode'] as String),
      selectedItemId: data['selectedItemId'] as String?,
      quantity: data['quantity'] as int,
      totalPrice: data['totalPrice'] as int,
      entries: [
        for (final raw in data['entries'] as List) _shopEntry(_map(raw)),
      ],
    ),
    'heal' => RuntimeHealServiceContent(
      title: data['title'] as String,
      message: data['message'] as String,
      wasHealed: data['wasHealed'] as bool,
      members: [
        for (final raw in data['members'] as List) _healMember(_map(raw)),
      ],
      display: data['display'] == null
          ? null
          : _healingDisplay(_map(data['display'])),
    ),
    'pc' => RuntimePcServiceContent(
      title: data['title'] as String,
      message: data['message'] as String,
      selectedBoxId: data['selectedBoxId'] as String,
      boxes: [for (final raw in data['boxes'] as List) _box(_map(raw))],
      party: [
        for (final raw in data['party'] as List) _decodePokemon(_map(raw)),
      ],
      stored: [
        for (final raw in data['stored'] as List) _decodePokemon(_map(raw)),
      ],
    ),
    'imagePuzzle' => RuntimeImagePuzzleServiceContent(progress: ImagePuzzleProgress.fromJson(_map(data['progress'])), bitmap: RuntimeImagePuzzleBitmap(bytes: base64Decode(data['bytes'] as String), width: data['width'] as int, height: data['height'] as int), selectedPieceId: data['selectedPieceId'] as int?, message: data['message'] as String?),
    'crafting' => RuntimeCraftingServiceContent(title: data['title'] as String, status: RuntimeCraftingStatus.values.byName(data['status'] as String),
      quantity: data['quantity'] as int, maximumQuantity: data['maximumQuantity'] as int, reviewing: data['reviewing'] as bool,
      selectedRecipeId: data['selectedRecipeId'] as String?, message: data['message'] as String?,
      pendingOutputLabel: data['pendingOutputLabel'] as String?, pendingOutputQuantity: data['pendingOutputQuantity'] as int?,
      recipes: [for (final raw in data['recipes'] as List) _craftingRecipe(_map(raw))]),
    'partyTrade' => RuntimePartyTradeServiceContent(
      phase: RuntimePartyTradePhase.values.byName(data['phase'] as String),
      firstIndividualId: data['firstIndividualId'] as String?,
      partnerIndividualId: data['partnerIndividualId'] as String?,
      completionMessage: data['completionMessage'] as String?,
      members: [
        for (final raw in data['members'] as List) _tradeMember(_map(raw)),
      ],
    ),
    _ => throw const FormatException('Unsupported companion service content.'),
  };

  static RuntimeCraftingRecipeSnapshot _craftingRecipe(Map<String, dynamic> data) => RuntimeCraftingRecipeSnapshot(
    recipeId: data['recipeId'] as String, label: data['label'] as String, inputLabel: data['inputLabel'] as String,
    outputLabel: data['outputLabel'] as String, inputQuantity: data['inputQuantity'] as int, outputQuantity: data['outputQuantity'] as int, ownedQuantity: data['ownedQuantity'] as int);

  static RuntimeShopEntrySnapshot _shopEntry(Map<String, dynamic> data) =>
      RuntimeShopEntrySnapshot(
        itemId: data['itemId'] as String,
        label: data['label'] as String,
        unitPrice: data['unitPrice'] as int,
        remainingStock: data['remainingStock'] as int?,
        ownedQuantity: data['ownedQuantity'] as int,
        canTransact: data['canTransact'] as bool,
        unavailableReason: data['unavailableReason'] as String?,
      );

  static RuntimeHealPartyMemberSnapshot _healMember(
    Map<String, dynamic> data,
  ) => RuntimeHealPartyMemberSnapshot(
    partyIndex: data['partyIndex'] as int,
    label: data['label'] as String,
    currentHp: data['currentHp'] as int,
    maxHp: data['maxHp'] as int,
    hasStatus: data['hasStatus'] as bool,
    depletedMoveCount: data['depletedMoveCount'] as int,
  );

  static RuntimeHealingDisplaySnapshot _healingDisplay(
    Map<String, dynamic> data,
  ) => RuntimeHealingDisplaySnapshot(
    mapId: data['mapId'] as String,
    entityId: data['entityId'] as String,
    memberCount: data['memberCount'] as int,
  );

  static RuntimePcBoxSnapshot _box(Map<String, dynamic> data) =>
      RuntimePcBoxSnapshot(
        boxId: data['boxId'] as String,
        label: data['label'] as String,
        count: data['count'] as int,
        capacity: data['capacity'] as int,
      );

  static RuntimePartyTradePokemonSnapshot _tradeMember(
    Map<String, dynamic> data,
  ) => RuntimePartyTradePokemonSnapshot(
    individualId: data['individualId'] as String,
    speciesId: data['speciesId'] as String,
    label: data['label'] as String,
    level: data['level'] as int,
  );

  static Map<String, Object?> _pokemon(RuntimePcPokemonSnapshot value) => {
    'targetId': value.targetId,
    'label': value.label,
    'speciesId': value.speciesId,
    'formId': value.formId,
    'level': value.level,
    'natureId': value.natureId,
    'abilityId': value.abilityId,
    'currentHp': value.currentHp,
    'gender': value.gender,
    'statusId': value.statusId,
    'isShiny': value.isShiny,
    'heldItemId': value.heldItemId,
    'nickname': value.nickname,
    'friendship': value.friendship,
    'originKind': value.originKind,
    'metMapId': value.metMapId,
    'metSourceId': value.metSourceId,
    'ballItemId': value.ballItemId,
    'metLevel': value.metLevel,
    'knownMoveIds': value.knownMoveIds,
    'canTransfer': value.canTransfer,
    'unavailableReason': value.unavailableReason,
    'summary': value.summary == null
        ? null
        : RuntimeCompanionPresentationCodec.encodeRuntimePokemonSummarySnapshot(
            value.summary!,
          ),
  };

  static RuntimePcPokemonSnapshot _decodePokemon(
    Map<String, dynamic> data,
  ) => RuntimePcPokemonSnapshot(
    targetId: data['targetId'] as String,
    label: data['label'] as String,
    speciesId: data['speciesId'] as String,
    formId: data['formId'] as String,
    level: data['level'] as int,
    natureId: data['natureId'] as String,
    abilityId: data['abilityId'] as String,
    currentHp: data['currentHp'] as int,
    gender: data['gender'] as String?,
    statusId: data['statusId'] as String,
    isShiny: data['isShiny'] as bool,
    heldItemId: data['heldItemId'] as String,
    nickname: data['nickname'] as String,
    friendship: data['friendship'] as int,
    originKind: data['originKind'] as String,
    metMapId: data['metMapId'] as String,
    metSourceId: data['metSourceId'] as String,
    ballItemId: data['ballItemId'] as String,
    metLevel: data['metLevel'] as int?,
    knownMoveIds: (data['knownMoveIds'] as List).cast<String>(),
    canTransfer: data['canTransfer'] as bool,
    unavailableReason: data['unavailableReason'] as String?,
    summary: data['summary'] == null
        ? null
        : RuntimeCompanionPresentationCodec.decodeRuntimePokemonSummarySnapshot(
            _map(data['summary']),
          ),
  );
}
