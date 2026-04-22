import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';

/// Convertit un snapshot Showdown `moves.json` vers le catalogue local `moves`.
///
/// M3 change volontairement la nature de la sortie :
/// - on ne produit plus un petit JSON ad hoc de catalogue "lisible" ;
/// - on construit de vrais objets `PokemonMove` du modèle canonique `map_core` ;
/// - puis on sérialise `PokemonMove.toJson()` dans `PokemonCatalogFile.entries`.
///
/// Cette décision borne proprement la suite :
/// - le convertisseur reste l'unique pipeline Showdown -> projet ;
/// - la normalisation du modèle canonique protège la sortie ;
/// - `map_editor` ne crée aucune structure parallèle ;
/// - `map_battle` ne lit toujours pas le JSON projet brut.
class ShowdownMoveCatalogConverter {
  const ShowdownMoveCatalogConverter();

  /// Produit un [PokemonCatalogFile] moves complet à partir du snapshot brut.
  ///
  /// Invariants M3 :
  /// - les entrées sont triées par id pour garder des diffs stables ;
  /// - chaque entrée provient d'un vrai `PokemonMove` ;
  /// - les limites de conversion sont matérialisées dans :
  ///   - `engineSupportLevel`
  ///   - `unsupportedReasons`
  ///   - `sourceRefs.showdownHooksPresent`
  PokemonCatalogFile convert(Map<String, dynamic> snapshot) {
    if (snapshot.isEmpty) {
      throw const EditorValidationException(
        'Showdown moves snapshot cannot be empty',
      );
    }

    final entries = snapshot.entries
        .map(
          (snapshotEntry) => _convertEntry(
            rawId: snapshotEntry.key,
            rawEntry: snapshotEntry.value,
          ),
        )
        .toList(growable: false)
      ..sort(
        (left, right) => ((left['id'] as String?) ?? '').compareTo(
          (right['id'] as String?) ?? '',
        ),
      );

    return PokemonCatalogFile(
      schemaVersion: 1,
      kind: 'pokemon_catalog',
      catalog: 'moves',
      meta: const PokemonDataMeta(
        description:
            'Moves catalog synchronized from the Pokémon Showdown moves snapshot.',
        sourcePriority: <String>['showdown', 'local_merge'],
        notes: <String>[
          'M3 converts Showdown move entries through the canonical PokemonMove model.',
          'The converter never derives battle logic from prose descriptions.',
          'Engine support limits are stored explicitly per move.',
        ],
      ),
      entries: entries,
    );
  }

  Map<String, dynamic> _convertEntry({
    required String rawId,
    required Object? rawEntry,
  }) {
    if (rawEntry is! Map) {
      throw EditorPersistenceException(
        'Showdown move entry "$rawId" must be an object',
      );
    }

    final entry = rawEntry.cast<String, dynamic>();
    final displayName = _readDisplayName(rawId, entry);
    final localId = _normalizeSnakeCaseId(displayName);
    if (localId.isEmpty) {
      throw EditorPersistenceException(
        'Showdown move entry "$rawId" does not expose a usable local id',
      );
    }

    final unsupportedReasons = <String>[];
    final seenUnsupportedReasons = <String>{};
    void addUnsupportedReason(String reason) {
      final normalized = reason.trim();
      if (normalized.isEmpty || !seenUnsupportedReasons.add(normalized)) {
        return;
      }
      unsupportedReasons.add(normalized);
    }

    // La capture des hooks Showdown doit être déterministe et honnête.
    //
    // Important :
    // - le snapshot HTTP JSON réel perd déjà les fonctions JS de Showdown ;
    // - mais le convertisseur doit rester capable de signaler ces hooks quand
    //   une source en mémoire les fournit encore (tests, outillage futur,
    //   audits plus riches à partir des sources TS).
    final hooksPresent = _collectShowdownHooks(entry);
    for (final hook in hooksPresent) {
      addUnsupportedReason('showdown_callback:$hook');
    }

    final type = _readRequiredLowerCaseString(
      rawId: rawId,
      fieldName: 'type',
      rawValue: entry['type'],
    );
    final category = _readRequiredCategory(rawId, entry['category']);
    final rawTarget = _readTrimmedString(entry['target']);
    if (rawTarget == null) {
      throw EditorPersistenceException(
        'Showdown move entry "$rawId" is missing a target',
      );
    }
    final target = _parseTarget(rawTarget);
    final resolvedTarget = target ?? PokemonMoveTarget.scripted;
    if (target == null) {
      addUnsupportedReason('unsupported_target:$rawTarget');
    }

    final flags = _mapFlags(entry['flags'], addUnsupportedReason);
    final effects = _buildStructuredEffects(
      entry: entry,
      rawTarget: rawTarget,
      addUnsupportedReason: addUnsupportedReason,
    );

    _collectUnsupportedTopLevelFields(
      entry: entry,
      addUnsupportedReason: addUnsupportedReason,
    );

    final move = PokemonMove(
      id: localId,
      name: displayName,
      names: <String, String>{'en': displayName},
      generation: _readOptionalInt(entry['gen']),
      source: 'showdown',
      type: type,
      category: category,
      target: resolvedTarget,
      basePower: _readBasePower(entry['basePower']),
      accuracy: _readAccuracy(rawId, entry['accuracy']),
      pp: _readOptionalInt(entry['pp']) ?? 0,
      noPpBoosts: _readBool(entry['noPPBoosts']),
      priority: _readOptionalInt(entry['priority']) ?? 0,
      critRatio: _readOptionalInt(entry['critRatio']) ?? 1,
      flags: flags,
      effects: _dedupeEffects(effects),
      shortDescription: _readTrimmedString(entry['shortDesc']) ?? '',
      description: _readTrimmedString(entry['desc']) ?? '',
      engineSupportLevel: _inferEngineSupportLevel(
        unsupportedReasons: unsupportedReasons,
        usesStandardDamageFlow: category != PokemonMoveCategory.status &&
            _readBasePower(entry['basePower']) > 0,
        effectsAreEmpty: effects.isEmpty,
      ),
      unsupportedReasons: unsupportedReasons,
      sourceRefs: PokemonMoveSourceRefs(
        showdownMoveId: rawId.trim().isEmpty ? null : rawId.trim(),
        showdownHooksPresent: hooksPresent,
      ),
    ).normalized();

    return move.toJson();
  }

  List<PokemonMoveEffect> _buildStructuredEffects({
    required Map<String, dynamic> entry,
    required String rawTarget,
    required void Function(String reason) addUnsupportedReason,
  }) {
    final effects = <PokemonMoveEffect>[];

    void addEffect(PokemonMoveEffect effect) {
      effects.add(effect);
    }

    // M3 assume explicitement que le flow de dégâts standards n'est plus un
    // effet structuré. `basePower` + `category` + `usesStandardDamageFlow`
    // suffisent à porter cette sémantique.
    _appendFixedDamageEffect(
      entry['damage'],
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );
    _appendMultiHitEffect(
      entry['multihit'],
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );

    _appendDirectStatusEffect(
      rawStatus: entry['status'],
      targetScope: _primaryTargetScopeForMoveTarget(rawTarget),
      addEffect: addEffect,
    );
    _appendDirectVolatileStatusEffect(
      rawVolatileStatus: entry['volatileStatus'],
      targetScope: _primaryTargetScopeForMoveTarget(rawTarget),
      addEffect: addEffect,
    );
    _appendModifyStatsEffect(
      rawBoosts: entry['boosts'],
      targetScope: _primaryTargetScopeForMoveTarget(rawTarget),
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );
    _appendFractionEffect(
      rawFraction: entry['heal'],
      kind: _FractionEffectKind.heal,
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );
    _appendFractionEffect(
      rawFraction: entry['drain'],
      kind: _FractionEffectKind.drain,
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );
    _appendFractionEffect(
      rawFraction: entry['recoil'],
      kind: _FractionEffectKind.recoil,
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );
    _appendFieldStringEffect(
      rawValue: entry['weather'],
      fieldName: 'weather',
      addEffect: addEffect,
    );
    _appendFieldStringEffect(
      rawValue: entry['terrain'],
      fieldName: 'terrain',
      addEffect: addEffect,
    );
    _appendFieldStringEffect(
      rawValue: entry['pseudoWeather'],
      fieldName: 'pseudoWeather',
      addEffect: addEffect,
    );
    _appendSelfSwitchEffect(entry['selfSwitch'], addEffect: addEffect);
    _appendForceSwitchEffect(entry['forceSwitch'], addEffect: addEffect);
    _appendBreakProtectEffect(entry['breaksProtect'], addEffect: addEffect);
    _appendSideConditionEffect(
      rawConditionId: entry['sideCondition'],
      targetScope: _sideConditionScopeForMoveTarget(rawTarget),
      addEffect: addEffect,
    );
    _appendSlotConditionEffect(
      rawConditionId: entry['slotCondition'],
      addEffect: addEffect,
    );

    // Les payloads `self` et `selfBoost` sont des seams non triviaux :
    // - ils modélisent des conséquences sur le lanceur, pas sur la cible ;
    // - certaines valeurs (`mustrecharge`) ont désormais un effet dédié ;
    // - d'autres payloads internes de Showdown restent volontairement hors
    //   scope et sont tracés comme limites explicites.
    _appendSelfPayloadEffects(
      rawSelf: entry['self'],
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );
    _appendSelfBoostEffects(
      rawSelfBoost: entry['selfBoost'],
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );
    _appendSecondaryEffects(
      rawSecondary: entry['secondary'],
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );
    _appendSecondariesEffects(
      rawSecondaries: entry['secondaries'],
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );

    // Les moves à charge sur deux tours sont un cas classique de faux positif
    // si on "simplifie" trop fort.
    //
    // On ne fabrique donc pas `charge_then_strike` à partir d'une simple
    // intuition sur les callbacks. En revanche, on marque la limite quand la
    // donnée source expose déjà des signaux suffisants (`flags.charge`,
    // callbacks, `condition`).
    if (_hasChargeThenStrikeSignal(entry)) {
      addUnsupportedReason('unsupported_mechanic:charge_then_strike');
    }

    return effects;
  }

  void _appendFixedDamageEffect(
    Object? rawDamage, {
    required void Function(PokemonMoveEffect effect) addEffect,
    required void Function(String reason) addUnsupportedReason,
  }) {
    if (rawDamage == null) {
      return;
    }
    if (rawDamage is num) {
      final value = rawDamage.toInt();
      if (value > 0) {
        addEffect(
          PokemonMoveEffect.fixedDamage(value: value),
        );
      } else {
        addUnsupportedReason('unsupported_mechanic:fixed_damage');
      }
      return;
    }
    if (rawDamage is String && rawDamage.trim().toLowerCase() == 'level') {
      addEffect(
        const PokemonMoveEffect.fixedDamage(usesUserLevel: true),
      );
      return;
    }
    addUnsupportedReason('unsupported_mechanic:fixed_damage');
  }

  void _appendMultiHitEffect(
    Object? rawMultiHit, {
    required void Function(PokemonMoveEffect effect) addEffect,
    required void Function(String reason) addUnsupportedReason,
  }) {
    if (rawMultiHit == null) {
      return;
    }
    if (rawMultiHit is num) {
      final hits = rawMultiHit.toInt();
      if (hits > 0) {
        addEffect(
          PokemonMoveEffect.multiHit(minHits: hits, maxHits: hits),
        );
      } else {
        addUnsupportedReason('unsupported_mechanic:multi_hit');
      }
      return;
    }
    if (rawMultiHit is List && rawMultiHit.length == 2) {
      final min = rawMultiHit[0];
      final max = rawMultiHit[1];
      if (min is num && max is num) {
        addEffect(
          PokemonMoveEffect.multiHit(
            minHits: min.toInt(),
            maxHits: max.toInt(),
          ),
        );
        return;
      }
    }
    addUnsupportedReason('unsupported_mechanic:multi_hit');
  }

  void _appendDirectStatusEffect({
    required Object? rawStatus,
    required PokemonMoveEffectTargetScope targetScope,
    required void Function(PokemonMoveEffect effect) addEffect,
    int? chance,
  }) {
    final statusId = _readLowerCaseString(rawStatus);
    if (statusId == null) {
      return;
    }
    addEffect(
      PokemonMoveEffect.applyStatus(
        targetScope: targetScope,
        chance: chance,
        statusId: statusId,
      ),
    );
  }

  void _appendDirectVolatileStatusEffect({
    required Object? rawVolatileStatus,
    required PokemonMoveEffectTargetScope targetScope,
    required void Function(PokemonMoveEffect effect) addEffect,
    int? chance,
  }) {
    final volatileStatusId = _readLowerCaseString(rawVolatileStatus);
    if (volatileStatusId == null) {
      return;
    }
    addEffect(
      PokemonMoveEffect.applyVolatileStatus(
        targetScope: targetScope,
        chance: chance,
        volatileStatusId: volatileStatusId,
      ),
    );
  }

  void _appendModifyStatsEffect({
    required Object? rawBoosts,
    required PokemonMoveEffectTargetScope targetScope,
    required void Function(PokemonMoveEffect effect) addEffect,
    required void Function(String reason) addUnsupportedReason,
    int? chance,
  }) {
    final stageChanges = _readStageChanges(
      rawBoosts,
      addUnsupportedReason: addUnsupportedReason,
    );
    if (stageChanges.isEmpty) {
      return;
    }
    if (chance != null &&
        !_supportsBattleProbabilisticModifyStats(
          targetScope: targetScope,
          stageChanges: stageChanges,
        )) {
      addUnsupportedReason('unsupported_mechanic:probabilistic_modify_stats');
    }
    addEffect(
      PokemonMoveEffect.modifyStats(
        targetScope: targetScope,
        chance: chance,
        stageChanges: stageChanges,
      ),
    );
  }

  void _appendFractionEffect({
    required Object? rawFraction,
    required _FractionEffectKind kind,
    required void Function(PokemonMoveEffect effect) addEffect,
    required void Function(String reason) addUnsupportedReason,
  }) {
    if (rawFraction == null) {
      return;
    }
    if (rawFraction is List && rawFraction.length == 2) {
      final numerator = rawFraction[0];
      final denominator = rawFraction[1];
      if (numerator is num && denominator is num) {
        final normalizedNumerator = numerator.toInt();
        final normalizedDenominator = denominator.toInt();
        switch (kind) {
          case _FractionEffectKind.heal:
            addEffect(
              PokemonMoveEffect.heal(
                numerator: normalizedNumerator,
                denominator: normalizedDenominator,
              ),
            );
          case _FractionEffectKind.drain:
            addEffect(
              PokemonMoveEffect.drain(
                numerator: normalizedNumerator,
                denominator: normalizedDenominator,
              ),
            );
          case _FractionEffectKind.recoil:
            addEffect(
              PokemonMoveEffect.recoil(
                numerator: normalizedNumerator,
                denominator: normalizedDenominator,
              ),
            );
        }
        return;
      }
    }
    addUnsupportedReason('unsupported_mechanic:${kind.reasonLabel}');
  }

  void _appendFieldStringEffect({
    required Object? rawValue,
    required String fieldName,
    required void Function(PokemonMoveEffect effect) addEffect,
  }) {
    final normalizedId = _readLowerCaseString(rawValue);
    if (normalizedId == null) {
      return;
    }

    switch (fieldName) {
      case 'weather':
        addEffect(
          PokemonMoveEffect.setWeather(weatherId: normalizedId),
        );
      case 'terrain':
        addEffect(
          PokemonMoveEffect.setTerrain(terrainId: normalizedId),
        );
      case 'pseudoWeather':
        addEffect(
          PokemonMoveEffect.setPseudoWeather(pseudoWeatherId: normalizedId),
        );
    }
  }

  void _appendSelfSwitchEffect(
    Object? rawSelfSwitch, {
    required void Function(PokemonMoveEffect effect) addEffect,
  }) {
    if (rawSelfSwitch == true) {
      addEffect(const PokemonMoveEffect.selfSwitch());
      return;
    }
    final mode = _readLowerCaseString(rawSelfSwitch);
    if (mode != null) {
      addEffect(PokemonMoveEffect.selfSwitch(mode: mode));
    }
  }

  void _appendForceSwitchEffect(
    Object? rawForceSwitch, {
    required void Function(PokemonMoveEffect effect) addEffect,
  }) {
    if (rawForceSwitch == true) {
      addEffect(const PokemonMoveEffect.forceSwitch());
    }
  }

  void _appendBreakProtectEffect(
    Object? rawBreaksProtect, {
    required void Function(PokemonMoveEffect effect) addEffect,
  }) {
    if (rawBreaksProtect == true) {
      addEffect(const PokemonMoveEffect.breakProtect());
    }
  }

  void _appendSideConditionEffect({
    required Object? rawConditionId,
    required PokemonMoveEffectTargetScope targetScope,
    required void Function(PokemonMoveEffect effect) addEffect,
  }) {
    final conditionId = _readLowerCaseString(rawConditionId);
    if (conditionId == null) {
      return;
    }
    addEffect(
      PokemonMoveEffect.setSideCondition(
        targetScope: targetScope,
        conditionId: conditionId,
      ),
    );
  }

  void _appendSlotConditionEffect({
    required Object? rawConditionId,
    required void Function(PokemonMoveEffect effect) addEffect,
  }) {
    final conditionId = _readLowerCaseString(rawConditionId);
    if (conditionId == null) {
      return;
    }
    addEffect(
      PokemonMoveEffect.setSlotCondition(conditionId: conditionId),
    );
  }

  void _appendSelfPayloadEffects({
    required Object? rawSelf,
    required void Function(PokemonMoveEffect effect) addEffect,
    required void Function(String reason) addUnsupportedReason,
    int? chance,
  }) {
    if (rawSelf is! Map) {
      return;
    }

    final self = rawSelf.cast<String, dynamic>();
    final supportedKeys = <String>{
      'boosts',
      'volatileStatus',
      'sideCondition',
      'pseudoWeather',
      'status',
    };

    _appendModifyStatsEffect(
      rawBoosts: self['boosts'],
      targetScope: PokemonMoveEffectTargetScope.self,
      chance: chance,
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );

    final selfVolatileStatus = _readLowerCaseString(self['volatileStatus']);
    if (selfVolatileStatus == 'mustrecharge') {
      addEffect(
        const PokemonMoveEffect.requireRecharge(),
      );
    } else if (selfVolatileStatus != null) {
      _appendDirectVolatileStatusEffect(
        rawVolatileStatus: selfVolatileStatus,
        targetScope: PokemonMoveEffectTargetScope.self,
        chance: chance,
        addEffect: addEffect,
      );
    }

    _appendDirectStatusEffect(
      rawStatus: self['status'],
      targetScope: PokemonMoveEffectTargetScope.self,
      chance: chance,
      addEffect: addEffect,
    );
    _appendSideConditionEffect(
      rawConditionId: self['sideCondition'],
      targetScope: PokemonMoveEffectTargetScope.allySide,
      addEffect: addEffect,
    );
    _appendFieldStringEffect(
      rawValue: self['pseudoWeather'],
      fieldName: 'pseudoWeather',
      addEffect: addEffect,
    );

    for (final entry in self.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key))) {
      if (supportedKeys.contains(entry.key) ||
          !_hasMeaningfulValue(entry.value)) {
        continue;
      }
      addUnsupportedReason('unsupported_mechanic:self.${entry.key}');
    }
  }

  void _appendSelfBoostEffects({
    required Object? rawSelfBoost,
    required void Function(PokemonMoveEffect effect) addEffect,
    required void Function(String reason) addUnsupportedReason,
  }) {
    if (rawSelfBoost is! Map) {
      return;
    }

    final selfBoost = rawSelfBoost.cast<String, dynamic>();
    _appendModifyStatsEffect(
      rawBoosts: selfBoost['boosts'],
      targetScope: PokemonMoveEffectTargetScope.self,
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );

    for (final entry in selfBoost.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key))) {
      if (entry.key == 'boosts' || !_hasMeaningfulValue(entry.value)) {
        continue;
      }
      addUnsupportedReason('unsupported_mechanic:selfBoost.${entry.key}');
    }
  }

  void _appendSecondaryEffects({
    required Object? rawSecondary,
    required void Function(PokemonMoveEffect effect) addEffect,
    required void Function(String reason) addUnsupportedReason,
  }) {
    if (rawSecondary is! Map) {
      return;
    }
    _appendSecondaryPayloadEffects(
      rawSecondary.cast<String, dynamic>(),
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
      reasonPrefix: 'secondary',
    );
  }

  void _appendSecondariesEffects({
    required Object? rawSecondaries,
    required void Function(PokemonMoveEffect effect) addEffect,
    required void Function(String reason) addUnsupportedReason,
  }) {
    if (rawSecondaries is! List) {
      return;
    }

    for (var index = 0; index < rawSecondaries.length; index++) {
      final secondary = rawSecondaries[index];
      if (secondary is! Map) {
        addUnsupportedReason(
            'unsupported_secondary_payload:secondaries[$index]');
        continue;
      }
      _appendSecondaryPayloadEffects(
        secondary.cast<String, dynamic>(),
        addEffect: addEffect,
        addUnsupportedReason: addUnsupportedReason,
        reasonPrefix: 'secondaries[$index]',
      );
    }
  }

  void _appendSecondaryPayloadEffects(
    Map<String, dynamic> secondary, {
    required void Function(PokemonMoveEffect effect) addEffect,
    required void Function(String reason) addUnsupportedReason,
    required String reasonPrefix,
  }) {
    final chance = _readSecondaryChance(
      secondary['chance'],
      addUnsupportedReason: addUnsupportedReason,
      reasonLabel: '$reasonPrefix.chance',
    );

    _appendDirectStatusEffect(
      rawStatus: secondary['status'],
      targetScope: PokemonMoveEffectTargetScope.target,
      chance: chance,
      addEffect: addEffect,
    );
    _appendDirectVolatileStatusEffect(
      rawVolatileStatus: secondary['volatileStatus'],
      targetScope: PokemonMoveEffectTargetScope.target,
      chance: chance,
      addEffect: addEffect,
    );
    _appendModifyStatsEffect(
      rawBoosts: secondary['boosts'],
      targetScope: PokemonMoveEffectTargetScope.target,
      chance: chance,
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );
    _appendSelfPayloadEffects(
      rawSelf: secondary['self'],
      chance: chance,
      addEffect: addEffect,
      addUnsupportedReason: addUnsupportedReason,
    );

    const supportedKeys = <String>{
      'chance',
      'status',
      'volatileStatus',
      'boosts',
      'self',
    };

    for (final entry in secondary.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key))) {
      if (supportedKeys.contains(entry.key) ||
          !_hasMeaningfulValue(entry.value)) {
        continue;
      }
      addUnsupportedReason('unsupported_secondary_payload:${entry.key}');
    }
  }

  int? _readSecondaryChance(
    Object? rawChance, {
    required void Function(String reason) addUnsupportedReason,
    required String reasonLabel,
  }) {
    if (rawChance == null) {
      return null;
    }
    if (rawChance is num) {
      final chance = rawChance.toInt();
      if (chance >= 1 && chance <= 100) {
        return chance;
      }
    }
    addUnsupportedReason('unsupported_secondary_payload:$reasonLabel');
    return null;
  }

  List<PokemonMoveStatStageChange> _readStageChanges(
    Object? rawBoosts, {
    required void Function(String reason) addUnsupportedReason,
  }) {
    if (rawBoosts is! Map) {
      return const <PokemonMoveStatStageChange>[];
    }

    final changes = <PokemonMoveStatStageChange>[];
    final sortedEntries = rawBoosts.entries.toList()
      ..sort((left, right) => '${left.key}'.compareTo('${right.key}'));

    for (final entry in sortedEntries) {
      final rawStat = '${entry.key}'.trim();
      final stat = _parseStatId(rawStat);
      final rawStages = entry.value;
      if (stat == null || rawStages is! num) {
        addUnsupportedReason('unsupported_mechanic:boosts');
        continue;
      }
      final stages = rawStages.toInt();
      if (stages == 0) {
        continue;
      }
      changes.add(
        PokemonMoveStatStageChange(stat: stat, stages: stages),
      );
    }

    return changes;
  }

  bool _supportsBattleProbabilisticModifyStats({
    required PokemonMoveEffectTargetScope targetScope,
    required List<PokemonMoveStatStageChange> stageChanges,
  }) {
    if (stageChanges.isEmpty) {
      return false;
    }
    if (targetScope != PokemonMoveEffectTargetScope.self &&
        targetScope != PokemonMoveEffectTargetScope.target) {
      return false;
    }

    return stageChanges.every(
      (change) => switch (change.stat) {
        PokemonMoveStatId.attack ||
        PokemonMoveStatId.defense ||
        PokemonMoveStatId.specialAttack ||
        PokemonMoveStatId.specialDefense ||
        PokemonMoveStatId.speed =>
          true,
        PokemonMoveStatId.accuracy || PokemonMoveStatId.evasion => false,
      },
    );
  }

  void _collectUnsupportedTopLevelFields({
    required Map<String, dynamic> entry,
    required void Function(String reason) addUnsupportedReason,
  }) {
    for (final mapEntry in entry.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key))) {
      final key = mapEntry.key;
      final value = mapEntry.value;
      if (_handledTopLevelFields.contains(key) ||
          _ignoredTopLevelMetadataFields.contains(key) ||
          !_hasMeaningfulValue(value)) {
        continue;
      }
      if (value is Function) {
        // Déjà tracé via `showdown_callback:<hookPath>`.
        continue;
      }
      addUnsupportedReason('unsupported_mechanic:$key');
    }
  }

  List<String> _collectShowdownHooks(Map<String, dynamic> entry) {
    final hooks = <String>[];
    final seen = <String>{};

    void visit(Object? value, String path) {
      if (value is Function) {
        if (seen.add(path)) {
          hooks.add(path);
        }
        return;
      }
      if (value is Map) {
        final entries = value.entries.toList()
          ..sort((left, right) => '${left.key}'.compareTo('${right.key}'));
        for (final nested in entries) {
          final key = '${nested.key}'.trim();
          if (key.isEmpty) {
            continue;
          }
          final nestedPath = path.isEmpty ? key : '$path.$key';
          visit(nested.value, nestedPath);
        }
        return;
      }
      if (value is List) {
        for (var index = 0; index < value.length; index++) {
          visit(value[index], '$path[$index]');
        }
      }
    }

    for (final key in entry.keys.toList()..sort()) {
      visit(entry[key], key);
    }

    hooks.sort();
    return hooks;
  }

  List<PokemonMoveFlag> _mapFlags(
    Object? rawFlags,
    void Function(String reason) addUnsupportedReason,
  ) {
    if (rawFlags is! Map) {
      return const <PokemonMoveFlag>[];
    }

    final flags = <PokemonMoveFlag>[];
    final seen = <PokemonMoveFlag>{};
    final sortedEntries = rawFlags.entries.toList()
      ..sort((left, right) => '${left.key}'.compareTo('${right.key}'));

    for (final entry in sortedEntries) {
      if (!_isTruthyFlagValue(entry.value)) {
        continue;
      }
      final flag = _parseFlag('${entry.key}');
      if (flag == null) {
        addUnsupportedReason('unknown_flag:${entry.key}');
        continue;
      }
      if (seen.add(flag)) {
        flags.add(flag);
      }
    }

    return flags;
  }

  PokemonMoveEngineSupportLevel _inferEngineSupportLevel({
    required List<String> unsupportedReasons,
    required bool usesStandardDamageFlow,
    required bool effectsAreEmpty,
  }) {
    // Politique M3 :
    // - `structured_supported` si rien d'important n'est perdu ;
    // - `structured_partial` si la structure principale est utile mais qu'il
    //   reste des limites honnêtement tracées ;
    // - `catalog_only` si réduire le move à ce squelette deviendrait trompeur.
    if (unsupportedReasons.isEmpty) {
      return PokemonMoveEngineSupportLevel.structuredSupported;
    }

    final hasCatalogOnlyBlockingReason = unsupportedReasons.any((reason) {
      return reason == 'unsupported_mechanic:charge_then_strike' ||
          reason == 'unsupported_mechanic:condition' ||
          reason == 'unsupported_mechanic:damage' ||
          reason == 'unsupported_mechanic:damageCallback' ||
          reason == 'showdown_callback:basePowerCallback' ||
          reason == 'showdown_callback:damageCallback';
    });

    if (hasCatalogOnlyBlockingReason) {
      return PokemonMoveEngineSupportLevel.catalogOnly;
    }

    // Si le move n'a ni flow de dégâts standard ni effet structuré utile, mais
    // dépend malgré tout de hooks ou de mécaniques non portées, on préfère
    // rester honnête et le signaler comme catalogue seulement.
    if (!usesStandardDamageFlow && effectsAreEmpty) {
      return PokemonMoveEngineSupportLevel.catalogOnly;
    }

    return PokemonMoveEngineSupportLevel.structuredPartial;
  }

  List<PokemonMoveEffect> _dedupeEffects(List<PokemonMoveEffect> effects) {
    final uniqueEffects = <PokemonMoveEffect>[];
    final seen = <String>{};
    for (final effect in effects) {
      final fingerprint = effect.normalized().toJson().toString();
      if (!seen.add(fingerprint)) {
        continue;
      }
      uniqueEffects.add(effect);
    }
    return uniqueEffects;
  }

  PokemonMoveAccuracy _readAccuracy(String rawId, Object? rawAccuracy) {
    if (rawAccuracy == true) {
      return const PokemonMoveAccuracy.alwaysHits();
    }
    if (rawAccuracy is num) {
      return PokemonMoveAccuracy.percent(value: rawAccuracy.toInt());
    }
    throw EditorPersistenceException(
      'Showdown move entry "$rawId" does not expose a supported accuracy payload',
    );
  }

  PokemonMoveCategory _readRequiredCategory(String rawId, Object? rawValue) {
    final normalized = _readLowerCaseString(rawValue);
    switch (normalized) {
      case 'physical':
        return PokemonMoveCategory.physical;
      case 'special':
        return PokemonMoveCategory.special;
      case 'status':
        return PokemonMoveCategory.status;
      default:
        throw EditorPersistenceException(
          'Showdown move entry "$rawId" exposes an unsupported category "$rawValue"',
        );
    }
  }

  PokemonMoveTarget? _parseTarget(String rawValue) {
    switch (rawValue.trim()) {
      case 'adjacentAlly':
        return PokemonMoveTarget.adjacentAlly;
      case 'adjacentAllyOrSelf':
        return PokemonMoveTarget.adjacentAllyOrSelf;
      case 'adjacentFoe':
        return PokemonMoveTarget.adjacentFoe;
      case 'all':
        return PokemonMoveTarget.all;
      case 'allAdjacent':
        return PokemonMoveTarget.allAdjacent;
      case 'allAdjacentFoes':
        return PokemonMoveTarget.allAdjacentFoes;
      case 'allies':
        return PokemonMoveTarget.allies;
      case 'allySide':
        return PokemonMoveTarget.allySide;
      case 'allyTeam':
        return PokemonMoveTarget.allyTeam;
      case 'any':
        return PokemonMoveTarget.any;
      case 'foeSide':
        return PokemonMoveTarget.foeSide;
      case 'normal':
        return PokemonMoveTarget.normal;
      case 'randomNormal':
        return PokemonMoveTarget.randomNormal;
      case 'scripted':
        return PokemonMoveTarget.scripted;
      case 'self':
        return PokemonMoveTarget.self;
    }
    return null;
  }

  PokemonMoveFlag? _parseFlag(String rawValue) {
    switch (rawValue.trim()) {
      case 'allyanim':
        return PokemonMoveFlag.allyAnim;
      case 'bypasssub':
        return PokemonMoveFlag.bypassSubstitute;
      case 'bite':
        return PokemonMoveFlag.bite;
      case 'bullet':
        return PokemonMoveFlag.bullet;
      case 'cantusetwice':
        return PokemonMoveFlag.cantUseTwice;
      case 'charge':
        return PokemonMoveFlag.charge;
      case 'contact':
        return PokemonMoveFlag.contact;
      case 'dance':
        return PokemonMoveFlag.dance;
      case 'defrost':
        return PokemonMoveFlag.defrost;
      case 'distance':
        return PokemonMoveFlag.distance;
      case 'failcopycat':
        return PokemonMoveFlag.failCopycat;
      case 'failencore':
        return PokemonMoveFlag.failEncore;
      case 'failinstruct':
        return PokemonMoveFlag.failInstruct;
      case 'failmefirst':
        return PokemonMoveFlag.failMeFirst;
      case 'failmimic':
        return PokemonMoveFlag.failMimic;
      case 'futuremove':
        return PokemonMoveFlag.futureMove;
      case 'gravity':
        return PokemonMoveFlag.gravity;
      case 'heal':
        return PokemonMoveFlag.heal;
      case 'metronome':
        return PokemonMoveFlag.metronome;
      case 'minimize':
        return PokemonMoveFlag.minimize;
      case 'mirror':
        return PokemonMoveFlag.mirror;
      case 'mustpressure':
        return PokemonMoveFlag.mustPressure;
      case 'noassist':
        return PokemonMoveFlag.noAssist;
      case 'nonsky':
        return PokemonMoveFlag.nonSky;
      case 'noparentalbond':
        return PokemonMoveFlag.noParentalBond;
      case 'nosketch':
        return PokemonMoveFlag.noSketch;
      case 'nosleeptalk':
        return PokemonMoveFlag.noSleepTalk;
      case 'pledgecombo':
        return PokemonMoveFlag.pledgeCombo;
      case 'powder':
        return PokemonMoveFlag.powder;
      case 'protect':
        return PokemonMoveFlag.protect;
      case 'pulse':
        return PokemonMoveFlag.pulse;
      case 'punch':
        return PokemonMoveFlag.punch;
      case 'recharge':
        return PokemonMoveFlag.recharge;
      case 'reflectable':
        return PokemonMoveFlag.reflectable;
      case 'slicing':
        return PokemonMoveFlag.slicing;
      case 'snatch':
        return PokemonMoveFlag.snatch;
      case 'sound':
        return PokemonMoveFlag.sound;
      case 'wind':
        return PokemonMoveFlag.wind;
    }
    return null;
  }

  PokemonMoveStatId? _parseStatId(String rawValue) {
    switch (rawValue.trim().toLowerCase()) {
      case 'atk':
        return PokemonMoveStatId.attack;
      case 'def':
        return PokemonMoveStatId.defense;
      case 'spa':
        return PokemonMoveStatId.specialAttack;
      case 'spd':
        return PokemonMoveStatId.specialDefense;
      case 'spe':
        return PokemonMoveStatId.speed;
      case 'accuracy':
        return PokemonMoveStatId.accuracy;
      case 'evasion':
        return PokemonMoveStatId.evasion;
    }
    return null;
  }

  PokemonMoveEffectTargetScope _primaryTargetScopeForMoveTarget(
    String rawTarget,
  ) {
    if (rawTarget == 'self') {
      return PokemonMoveEffectTargetScope.self;
    }
    return PokemonMoveEffectTargetScope.target;
  }

  PokemonMoveEffectTargetScope _sideConditionScopeForMoveTarget(
    String rawTarget,
  ) {
    switch (rawTarget) {
      case 'allySide':
      case 'allyTeam':
        return PokemonMoveEffectTargetScope.allySide;
      default:
        return PokemonMoveEffectTargetScope.foeSide;
    }
  }

  String _readDisplayName(String rawId, Map<String, dynamic> entry) {
    final explicitName = _readTrimmedString(entry['name']);
    if (explicitName != null && explicitName.isNotEmpty) {
      return explicitName;
    }
    return _humanizeIdentifier(rawId);
  }

  String _readRequiredLowerCaseString({
    required String rawId,
    required String fieldName,
    required Object? rawValue,
  }) {
    final value = _readLowerCaseString(rawValue);
    if (value == null) {
      throw EditorPersistenceException(
        'Showdown move entry "$rawId" is missing a supported $fieldName',
      );
    }
    return value;
  }

  String? _readLowerCaseString(Object? rawValue) {
    final value = _readTrimmedString(rawValue);
    if (value == null || value.isEmpty) {
      return null;
    }
    return value.toLowerCase();
  }

  String? _readTrimmedString(Object? rawValue) {
    final value = rawValue as String?;
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  int? _readOptionalInt(Object? rawValue) {
    return (rawValue as num?)?.toInt();
  }

  int _readBasePower(Object? rawValue) {
    return (rawValue as num?)?.toInt() ?? 0;
  }

  bool _readBool(Object? rawValue) => rawValue == true;

  bool _isTruthyFlagValue(Object? value) {
    if (value == true) {
      return true;
    }
    return value is num && value != 0;
  }

  bool _hasChargeThenStrikeSignal(Map<String, dynamic> entry) {
    final flags = entry['flags'];
    final hasChargeFlag = flags is Map && _isTruthyFlagValue(flags['charge']);
    if (!hasChargeFlag) {
      return false;
    }

    if (_hasMeaningfulValue(entry['condition'])) {
      return true;
    }

    for (final hook in _collectShowdownHooks(entry)) {
      if (hook == 'onTryMove' ||
          hook == 'onTry' ||
          hook == 'beforeMoveCallback' ||
          hook == 'onPrepareHit') {
        return true;
      }
    }

    return false;
  }

  bool _hasMeaningfulValue(Object? value) {
    if (value == null || value == false) {
      return false;
    }
    if (value is String) {
      return value.trim().isNotEmpty;
    }
    if (value is List) {
      return value.isNotEmpty;
    }
    if (value is Map) {
      return value.isNotEmpty;
    }
    return true;
  }

  String _normalizeSnakeCaseId(String rawValue) {
    final lowerCase = rawValue.trim().toLowerCase();
    if (lowerCase.isEmpty) {
      return '';
    }

    final separated = lowerCase.replaceAll(RegExp(r'[\s-]+'), '_');
    final asciiSafe = separated.replaceAll(RegExp(r'[^a-z0-9_]+'), '');
    final collapsed = asciiSafe.replaceAll(RegExp(r'_+'), '_');
    return collapsed.replaceAll(RegExp(r'^_|_$'), '');
  }

  String _humanizeIdentifier(String rawId) {
    final prepared = rawId
        .trim()
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .trim();

    if (prepared.isEmpty) {
      return rawId;
    }

    return prepared
        .split(RegExp(r'\s+'))
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

enum _FractionEffectKind {
  heal('heal'),
  drain('drain'),
  recoil('recoil');

  const _FractionEffectKind(this.reasonLabel);

  final String reasonLabel;
}

const Set<String> _handledTopLevelFields = <String>{
  'name',
  'type',
  'category',
  'target',
  'gen',
  'pp',
  'priority',
  'basePower',
  'accuracy',
  'shortDesc',
  'desc',
  'noPPBoosts',
  'critRatio',
  'flags',
  'status',
  'volatileStatus',
  'boosts',
  'selfBoost',
  'self',
  'secondary',
  'secondaries',
  'drain',
  'recoil',
  'heal',
  'multihit',
  'damage',
  'weather',
  'terrain',
  'pseudoWeather',
  'selfSwitch',
  'forceSwitch',
  'breaksProtect',
  'sideCondition',
  'slotCondition',
};

const Set<String> _ignoredTopLevelMetadataFields = <String>{
  'num',
  'contestType',
  // Mini-lot starter coverage :
  // - `zMove` décrit uniquement le comportement Z-Move historique du move ;
  // - cette métadonnée n'altère pas l'exécution du move de base dans le slice
  //   singles local actuellement supporté ;
  // - la conserver comme "unsupported reason" déclassait à tort des moves déjà
  //   honnêtement portables comme `tailwhip` ou `withdraw` ;
  // - on l'ignore donc ici comme métadonnée de catalogue, au même titre que
  //   `num` et `contestType`, sans prétendre ouvrir le moindre support Z-Move.
  'zMove',
};
