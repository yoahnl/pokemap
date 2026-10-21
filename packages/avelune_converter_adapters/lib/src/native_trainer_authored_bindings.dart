import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'native_psdk_trainer_bundle.dart';

final class NativeTrainerAuthoredBindings {
  NativeTrainerAuthoredBindings._(
      this.moves, this.items, this.evidence, this.errors);
  final Map<String, String> moves;
  final Map<String, ProjectItemDefinition> items;
  final Map<String, Object?> evidence;
  final Map<String, ContractError> errors;

  static Future<NativeTrainerAuthoredBindings> read({
    required SourceSnapshot snapshot,
    required SourcePbsProject source,
    required SourceFilePort files,
    required NativePsdkCatalog native,
    required Set<String> moveSymbols,
    required Set<String> itemSymbols,
    ScanCancellation? cancellation,
  }) async {
    if (moveSymbols.length > 8192 || itemSymbols.length > 8192) {
      _fail('quota',
          'Authored catalog identities exceed the bounded request budget.');
    }
    final moves = <String, String>{};
    final items = <String, ProjectItemDefinition>{};
    final errors = <String, ContractError>{};
    final rows = <Map<String, Object?>>[];
    for (final group in [
      (
        family: SourcePbsFamily.moves,
        symbols: moveSymbols,
        path: 'Data/moves.dat',
        type: 'GameData::Move',
        domain: 'move'
      ),
      (
        family: SourcePbsFamily.items,
        symbols: itemSymbols,
        path: 'Data/items.dat',
        type: 'GameData::Item',
        domain: 'item'
      )
    ]) {
      if (group.symbols.isEmpty) continue;
      Map<String, Map<String, Object?>> compiled;
      SourceFileEntry file;
      try {
        final matches = snapshot.entries
            .where((entry) => entry.relativePath == group.path)
            .toList();
        if (matches.length != 1 ||
            matches.single.kind != SourceNodeKind.file ||
            matches.single.sha256 == null ||
            matches.single.byteLength > 8388608) {
          _fail(
              'witness', 'An exact bounded ${group.path} witness is required.');
        }
        file = matches.single;
        final bytes = await files.read(file.fileId);
        cancellation?.check();
        if (bytes.length != file.byteLength ||
            crypto.sha256.convert(bytes).toString() != file.sha256!.value) {
          _fail('source_changed',
              'Authored catalog bytes differ from the sealed source.');
        }
        compiled = _compiled(bytes, group.path, group.type, group.symbols);
      } on ContractError catch (error) {
        if (error.code == 'source.cancelled') rethrow;
        for (final symbol in group.symbols) {
          errors['${group.domain}:$symbol'] = error;
        }
        continue;
      }
      for (final symbol in group.symbols.toList()..sort()) {
        cancellation?.check();
        try {
          final candidates = source.entries
              .where((entry) =>
                  entry.family == group.family &&
                  entry.identity?.sourceSymbol == symbol &&
                  entry.identity?.form == 0)
              .toList();
          if (candidates.length != 1 || candidates.single.isBlocked) {
            _fail('pbs_identity',
                'Every authored $symbol requires one unblocked PBS identity.');
          }
          final entry = candidates.single, record = compiled[symbol];
          if (entry.fields.map((field) => field.key).toSet().length !=
              entry.fields.length) {
            _fail('pbs_field', 'Authored catalog fields must be unique.');
          }
          if (record == null || record['@id'] != symbol) {
            _fail('compiled_identity',
                'Authored $symbol has no unique compiled identity.');
          }
          String text(String key) {
            final fields = entry.fieldsNamed(key);
            if (fields.length != 1 || fields.single.values.length != 1) {
              _fail('pbs_field',
                  'Authored $symbol requires one exact $key field.');
            }
            return fields.single.values.single;
          }

          int number(String key, [int? fallback]) {
            if (entry.fieldsNamed(key).isEmpty && fallback != null) {
              return fallback;
            }
            final value = int.tryParse(text(key));
            if (value == null) {
              _fail('pbs_field', 'Authored $symbol has a noninteger $key.');
            }
            return value;
          }

          final name = text('Name');
          if (record['@real_name'] != name) {
            _fail('catalog_changed', 'PBS and compiled $symbol names differ.');
          }
          if (group.family == SourcePbsFamily.moves) {
            if (entry.fields.any((field) => !const {
                  'Name',
                  'Type',
                  'Category',
                  'Power',
                  'Accuracy',
                  'TotalPP',
                  'Priority',
                  'Target',
                  'FunctionCode',
                  'EffectChance',
                  'Flags',
                  'Description',
                }.contains(field.key))) {
              _fail('pbs_override',
                  'Unknown authored move fields remain unsupported.');
            }
            final declared = _moveIdentities[symbol];
            if (declared == null) {
              _fail('move_identity',
                  'Authored $symbol has no declared native identity.');
            }
            final move = native.movesById[declared.$1];
            final metadata = _moveMetadataDifferences[symbol];
            final category = const {
              'Physical': 0,
              'Special': 1,
              'Status': 2
            }[text('Category')];
            final fields = {
              '@type': text('Type'),
              '@category': category,
              '@power': number('Power', 0),
              '@accuracy': number('Accuracy'),
              '@total_pp': number('TotalPP'),
              '@priority': number('Priority', 0),
              '@target': text('Target'),
              '@function_code': text('FunctionCode'),
              '@effect_chance': number('EffectChance', 0),
              '@flags': entry.fieldsNamed('Flags').isEmpty
                  ? <String>[]
                  : entry.field('Flags')!.values
            };
            if (category == null ||
                fields.entries.any((field) =>
                    canonicalJsonOf(record[field.key]) !=
                    canonicalJsonOf(field.value)) ||
                fields['@function_code'] != declared.$2) {
              _fail('catalog_changed',
                  'Authored $symbol differs from its compiled standard move identity.');
            }
            if (move == null ||
                move.id != declared.$1 ||
                (metadata == null
                    ? move.name != name
                    : name != metadata.$1 ||
                        move.name != metadata.$2 ||
                        text('Category') != metadata.$3 ||
                        move.category.name != metadata.$4) ||
                move.type != text('Type').toLowerCase() ||
                (metadata == null &&
                    move.category.name != text('Category').toLowerCase()) ||
                move.pp <= 0) {
              _fail('native_move_identity',
                  'The declared native identity for $symbol is absent or differs.');
            }
            final projected =
                const CanonicalPsdkMoveProjector().project(move: move);
            if (projected.id != move.id ||
                projected.battleEngineMethod != declared.$3) {
              _fail('native_move_projection',
                  'The declared native move behavior for $symbol differs.');
            }
            moves[symbol] = move.id;
            rows.add({
              'domain': 'move',
              'sourceSymbol': symbol,
              'sourceLocator': entry.headerLocator.toJson(),
              'compiledWitness': file.toJson(),
              'compiledRecordHash': canonicalHashOf(record).value,
              'sourcePbsHash': canonicalHashOf(entry.toJson()).value,
              'nativeMoveId': move.id,
              'nativeMoveHash': canonicalHashOf(move.toJson()).value,
              'sourceFunctionCode': declared.$2,
              'nativeEngineMethod': declared.$3,
              'sourcePower': fields['@power'],
              'nativePower': move.basePower,
              'sourcePP': fields['@total_pp'],
              'nativePP': move.pp,
              'sourceCategory': text('Category'),
              'nativeCategory': move.category.name,
              'sourceName': name,
              'nativeName': move.name,
              'balancePolicy': 'native-avelune-move',
              'battleRules': 'avelune',
              'sourceBattleLogicImported': false
            });
          } else {
            if (entry.fields.any((field) => !const {
                  'Name',
                  'NamePlural',
                  'PortionName',
                  'PortionNamePlural',
                  'Pocket',
                  'Price',
                  'SellPrice',
                  'BPPrice',
                  'FieldUse',
                  'BattleUse',
                  'Flags',
                  'Consumable',
                  'ShowQuantity',
                  'Move',
                  'Description',
                }.contains(field.key))) {
              _fail('pbs_override',
                  'Unknown authored medicine fields remain unsupported.');
            }
            final id = const {
              'FULLHEAL': 'full-heal',
              'HYPERPOTION': 'hyper-potion'
            }[symbol];
            if (id == null) {
              _fail('item_identity',
                  'Authored $symbol has no declared native battle medicine identity.');
            }
            if (record['@pocket'] != 2 ||
                number('Pocket') != 2 ||
                record['@field_use'] != 1 ||
                text('FieldUse') != 'OnPokemon' ||
                record['@battle_use'] != 1 ||
                text('BattleUse') != 'OnPokemon' ||
                record['@consumable'] != true ||
                (entry.fieldsNamed('Consumable').isNotEmpty &&
                    text('Consumable') != 'true') ||
                entry.fieldsNamed('Move').isNotEmpty ||
                record['@move'] != null ||
                canonicalJsonOf(record['@flags']) !=
                    canonicalJsonOf(['Fling_30']) ||
                canonicalJsonOf(entry.field('Flags')?.values) !=
                    canonicalJsonOf(['Fling_30'])) {
              _fail('item_contract',
                  'Authored $symbol is not the declared consumable battle medicine.');
            }
            final definition =
                mvpItemCatalog.entries.singleWhere((item) => item.id == id);
            if (definition.displayName != name ||
                !isEligibleTrainerBattleItem(definition)) {
              _fail('native_item_contract',
                  'The canonical native medicine for $symbol differs.');
            }
            items[symbol] = definition;
            rows.add({
              'domain': 'item',
              'sourceSymbol': symbol,
              'sourceLocator': entry.headerLocator.toJson(),
              'compiledWitness': file.toJson(),
              'compiledRecordHash': canonicalHashOf(record).value,
              'sourcePbsHash': canonicalHashOf(entry.toJson()).value,
              'nativeItem': definition.toJson(),
              'nativeItemHash': canonicalHashOf(definition.toJson()).value,
              'balancePolicy': 'native-avelune-medicine',
              'sourceMedicineSymbol': symbol,
              'nativeMedicineUses': definition.toJson()['uses'],
              'sourceHealingAmountImported': false,
              'battleRules': 'avelune',
              'sourceHandlersExecuted': false
            });
          }
        } on ContractError catch (error) {
          if (error.code == 'source.cancelled') rethrow;
          errors['${group.domain}:$symbol'] = error;
        } on CanonicalPsdkMoveProjectionException catch (error) {
          errors['${group.domain}:$symbol'] = ContractError(
              'native_trainer.authored_move_projection', symbol, error.reason);
        } on ArgumentError catch (error) {
          errors['${group.domain}:$symbol'] = ContractError(
              'native_trainer.authored_move_projection', symbol, '$error');
        }
      }
    }
    return NativeTrainerAuthoredBindings._(
        Map.unmodifiable(moves),
        Map.unmodifiable(items),
        {
          'policy': 'declared-identities-pbs-compiled-native-v1',
          'bindings': rows,
          'nativeItemCatalogHash':
              canonicalHashOf(mvpItemCatalog.toJson()).value
        },
        Map.unmodifiable(errors));
  }
}

Map<String, Map<String, Object?>> _compiled(
    List<int> bytes, String path, String type, Set<String> requested) {
  try {
    final document = const MarshalDecoder().decode(bytes,
        sourcePath: path,
        limits: const MarshalDecodeLimits(
            maxInputBytes: 8388608, maxNodes: 300000));
    final root = document.node(document.rootId);
    if (root.kind != MarshalKind.hash ||
        root.defaultValue != null ||
        root.extensions.isNotEmpty ||
        root.userClass != null ||
        root.instanceVariables.isNotEmpty) {
      _fail('compiled_shape', 'An inert catalog hash is required.');
    }
    final result = <String, Map<String, Object?>>{};
    Object? value(int id, [int depth = 0]) {
      final node = document.node(id);
      if (depth > 8 || node.extensions.isNotEmpty || node.userClass != null) {
        _fail('compiled_shape',
            'Authored catalog values must be bounded inert literals.');
      }
      if (node.instanceVariables.isNotEmpty &&
          (node.kind != MarshalKind.string ||
              node.instanceVariables.any((field) {
                final key = document.node(field.key),
                    encoded = document.node(field.value);
                return key.kind != MarshalKind.symbol ||
                    !((key.name == 'E' &&
                            encoded.kind == MarshalKind.boolean) ||
                        (key.name == 'encoding' &&
                            encoded.kind == MarshalKind.string));
              }))) {
        _fail('compiled_shape',
            'Only string encoding metadata is allowed on literal catalog values.');
      }
      return switch (node.kind) {
        MarshalKind.nil => null,
        MarshalKind.boolean => node.booleanValue,
        MarshalKind.integer => node.integerValue!.toInt(),
        MarshalKind.symbol => node.name,
        MarshalKind.string => node.text().text,
        MarshalKind.array
            when node.elements.length <= 128 &&
                node.instanceVariables.isEmpty =>
          node.elements.map((child) => value(child, depth + 1)).toList(),
        _ => throw ContractError('native_trainer.authored_compiled_shape', path,
            'Unsupported catalog literal.'),
      };
    }

    for (final pair in root.pairs) {
      final key = document.node(pair.key);
      if (key.kind != MarshalKind.symbol ||
          key.extensions.isNotEmpty ||
          key.userClass != null) {
        _fail('compiled_identity', 'Catalog keys must be exact symbols.');
      }
      if (!requested.contains(key.name)) continue;
      final node = document.node(pair.value);
      if (result.containsKey(key.name) ||
          node.kind != MarshalKind.object ||
          node.className != type ||
          node.extensions.isNotEmpty ||
          node.userClass != null) {
        _fail('compiled_identity',
            'Every requested catalog identity must be unique and typed.');
      }
      final fields = <String, Object?>{};
      for (final field in node.instanceVariables) {
        final name = document.node(field.key);
        if (name.kind != MarshalKind.symbol ||
            fields.containsKey(name.name) ||
            name.extensions.isNotEmpty ||
            name.userClass != null ||
            name.instanceVariables.isNotEmpty) {
          _fail('compiled_shape', 'Catalog fields must be unique symbols.');
        }
        final content = document.node(field.value);
        if ((const {'@id', '@type', '@target'}.contains(name.name) &&
                content.kind != MarshalKind.symbol) ||
            (const {'@real_name', '@function_code'}.contains(name.name) &&
                content.kind != MarshalKind.string)) {
          _fail('compiled_shape',
              'Catalog identities and behavior metadata require their exact literal types.');
        }
        fields[name.name!] = value(field.value);
      }
      final allowed = type == 'GameData::Move'
          ? const {
              '@id',
              '@real_name',
              '@type',
              '@category',
              '@power',
              '@accuracy',
              '@total_pp',
              '@target',
              '@priority',
              '@function_code',
              '@flags',
              '@effect_chance',
              '@real_description',
              '@pbs_file_suffix'
            }
          : const {
              '@id',
              '@real_name',
              '@real_name_plural',
              '@real_portion_name',
              '@real_portion_name_plural',
              '@pocket',
              '@price',
              '@sell_price',
              '@bp_price',
              '@field_use',
              '@battle_use',
              '@flags',
              '@consumable',
              '@show_quantity',
              '@move',
              '@real_description',
              '@pbs_file_suffix'
            };
      if (!fields.keys.every(allowed.contains)) {
        _fail('compiled_override',
            'Unknown authored catalog fields remain unsupported.');
      }
      result[key.name!] = fields;
    }
    return result;
  } on BinaryDecodeError catch (error) {
    _fail(
        'compiled_decode', 'Authored catalog decoding failed: ${error.code}.');
  }
}

Never _fail(String code, String message) =>
    throw ContractError('native_trainer.authored_$code', r'$', message);

const _moveIdentities = <String, (String, String, String)>{
  'GROWL': ('growl', 'LowerTargetAttack1', 's_stat'),
  'SCRATCH': ('scratch', 'None', 's_basic'),
  'TAILWHIP': ('tail_whip', 'LowerTargetDefense1', 's_stat'),
  'BITE': ('bite', 'FlinchTarget', 's_basic'),
  'BODYSLAM': ('body_slam', 'ParalyzeTarget', 's_stomp'),
  'BOUNCE': (
    'bounce',
    'TwoTurnAttackInvulnerableInSkyParalyzeTarget',
    's_2turns'
  ),
  'DOUBLEKICK': ('double_kick', 'HitTwoTimes', 's_2hits'),
  'EARTHQUAKE': ('earthquake', 'DoublePowerIfTargetUnderground', 's_basic'),
  'FIREBLAST': ('fire_blast', 'BurnTarget', 's_basic'),
  'FIRESPIN': ('fire_spin', 'BindTarget', 's_bind'),
  'MUDSLAP': ('mud_slap', 'LowerTargetAccuracy1', 's_basic'),
  'POISONSTING': ('poison_sting', 'PoisonTarget', 's_basic'),
  'ROAR': ('roar', 'SwitchOutTargetStatusMove', 's_roar'),
  'ROCKBLAST': ('rock_blast', 'HitTwoToFiveTimes', 's_multi_hit'),
  'SANDTOMB': ('sand_tomb', 'BindTarget', 's_bind'),
  'SCARYFACE': ('scary_face', 'LowerTargetSpeed2', 's_stat'),
  'SLASH': ('slash', 'None', 's_basic'),
  'STOMP': ('stomp', 'FlinchTarget', 's_stomp'),
  'TAKEDOWN': ('take_down', 'RecoilQuarterOfDamageDealt', 's_recoil'),
  'THRASH': ('thrash', 'MultiTurnAttackConfuseUserAtEnd', 's_thrash'),
  'ACID': ('acid', 'LowerTargetSpDef1', 's_basic'),
  'ACIDARMOR': ('acid_armor', 'RaiseUserDefense2', 's_self_stat'),
  'BARRIER': ('barrier', 'RaiseUserDefense2', 's_self_stat'),
  'BATONPASS': ('baton_pass', 'SwitchOutUserPassOnEffects', 's_baton_pass'),
  'BIND': ('bind', 'BindTarget', 's_bind'),
  'CALMMIND': ('calm_mind', 'RaiseUserSpAtkSpDef1', 's_self_stat'),
  'CONSTRICT': ('constrict', 'LowerTargetSpeed1', 's_basic'),
  'DEFENSECURL': ('defense_curl', 'RaiseUserDefense1CurlUpUser', 's_self_stat'),
  'DOUBLETEAM': ('double_team', 'RaiseUserEvasion1', 's_self_stat'),
  'FUTURESIGHT': ('future_sight', 'AttackTwoTurnsLater', 's_future_sight'),
  'GIGADRAIN': ('giga_drain', 'HealUserByHalfOfDamageDone', 's_absorb'),
  'GUST': ('gust', 'DoublePowerIfTargetInSky', 's_basic'),
  'HARDEN': ('harden', 'RaiseUserDefense1', 's_self_stat'),
  'INGRAIN': ('ingrain', 'StartHealUserEachTurnTrapUserInBattle', 's_ingrain'),
  'LEECHLIFE': ('leech_life', 'HealUserByHalfOfDamageDone', 's_absorb'),
  'MINIMIZE': ('minimize', 'RaiseUserEvasion2MinimizeUser', 's_minimize'),
  'POISONPOWDER': ('poison_powder', 'PoisonTarget', 's_status'),
  'PSYBEAM': ('psybeam', 'ConfuseTarget', 's_basic'),
  'PSYCHIC': ('psychic', 'LowerTargetSpDef1', 's_basic'),
  'QUICKATTACK': ('quick_attack', 'None', 's_basic'),
  'RAPIDSPIN': (
    'rapid_spin',
    'RemoveUserBindingAndEntryHazards',
    's_rapid_spin'
  ),
  'RECOVER': ('recover', 'HealUserHalfOfTotalHP', 's_heal'),
  'REFLECT': (
    'reflect',
    'StartWeakenPhysicalDamageAgainstUserSide',
    's_reflect'
  ),
  'ROCKTOMB': ('rock_tomb', 'LowerTargetSpeed1', 's_basic'),
  'SCREECH': ('screech', 'LowerTargetDefense2', 's_stat'),
  'SELFDESTRUCT': ('self_destruct', 'UserFaintsExplosive', 's_explosion'),
  'SHOCKWAVE': ('shock_wave', 'None', 's_basic'),
  'SLEEPPOWDER': ('sleep_powder', 'SleepTarget', 's_status'),
  'SLUDGE': ('sludge', 'PoisonTarget', 's_basic'),
  'SMOKESCREEN': ('smokescreen', 'LowerTargetAccuracy1', 's_stat'),
  'SONICBOOM': ('sonic_boom', 'FixedDamage20', 's_fixed_damage'),
  'STUNSPORE': ('stun_spore', 'ParalyzeTarget', 's_status'),
  'SUPERSONIC': ('supersonic', 'ConfuseTarget', 's_status'),
  'SWIFT': ('swift', 'None', 's_basic'),
  'TACKLE': ('tackle', 'None', 's_basic'),
  'THUNDERWAVE': ('thunder_wave', 'ParalyzeTargetIfNotTypeImmune', 's_status'),
  'TOXIC': ('toxic', 'BadPoisonTarget', 's_status'),
  'WATERPULSE': ('water_pulse', 'ConfuseTarget', 's_basic'),
};

const _moveMetadataDifferences = <String, (String, String, String, String)>{
  'MUDSLAP': ('Mud-Slap', 'Mud Slap', 'Special', 'special'),
  'SELFDESTRUCT': ('Self-Destruct', 'Self Destruct', 'Physical', 'physical'),
  'SONICBOOM': ('Sonic Boom', 'Sonic Boom', 'Special', 'physical'),
};
