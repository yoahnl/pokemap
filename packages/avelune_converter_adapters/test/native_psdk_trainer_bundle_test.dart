import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/src/generated/native_psdk_trainer_bundle_data.dart';
import 'package:avelune_converter_adapters/src/native_psdk_trainer_bundle.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('retains native progression moves independently of roster defaults', () {
    final sources = _fixtureSources();
    _addNativeMove(sources, 'future_cut', level: 20);
    final native = const NativePsdkTrainerBundleBuilder().build(
        files: sources,
        requests: [
          NativePsdkCatalogRequest(baseId: 'fixture', form: 0, level: 1)
        ]);
    expect(native.movesById['future_cut']!.engineSupportLevel,
        PokemonMoveEngineSupportLevel.structuredPartial);
    expect(native.movesById['future_cut']!.unsupportedReasons,
        ['psdk_method:s_basic']);
    expect(native.evidence['runtimeBattleBuilderQualified'], isFalse);
  });

  test('requests exact forms and preserves explicit moves outside learnsets',
      () {
    final sources = _fixtureSources();
    _addNativeMove(sources, 'outside_cut');
    final requests = [
      NativePsdkCatalogRequest(
          baseId: 'fixture',
          form: 1,
          level: 5,
          explicitMoveIds: ['outside_cut', 'cut']),
      NativePsdkCatalogRequest(baseId: 'fixture', form: 0, level: 5),
    ];
    final native = const NativePsdkTrainerBundleBuilder()
        .build(files: sources, requests: requests);
    expect(native.evidence['nativeRequestMoveBindings'], [
      {
        'baseId': 'fixture',
        'form': 0,
        'level': 5,
        'movePolicy': 'nativeDefaults',
        'moveIds': ['cut']
      },
      {
        'baseId': 'fixture',
        'form': 1,
        'level': 5,
        'movePolicy': 'explicit',
        'moveIds': ['outside_cut', 'cut']
      },
    ]);
    expect(native.movesById.keys, ['cut', 'outside_cut']);
    expect(
        native.learnsetsBySpeciesId['fixture_form1']!.startingMoves, ['cut']);
    expect(native.speciesById['fixture_form1']!.names, isEmpty);
    expect(native.evidence['nativeNamesQualified'], isFalse);
    expect(native.evidence.containsKey('sourceTrainerRosters'), isFalse);
    expect(
        canonicalHashOf(native.toJson()),
        canonicalHashOf(const NativePsdkTrainerBundleBuilder()
            .build(
                files: sources.reversed.toList(),
                requests: requests.reversed.toList())
            .toJson()));
  });

  test('does not replace explicit moves with defaults for an empty learnset',
      () {
    final sources = _fixtureSources();
    _mutateSource(sources, 'Data/Studio/pokemon/fixture.json',
        (raw) => ((raw['forms'] as List)[1] as Map)['moveSet'] = []);
    final native =
        const NativePsdkTrainerBundleBuilder().build(files: sources, requests: [
      NativePsdkCatalogRequest(
          baseId: 'fixture', form: 1, level: 1, explicitMoveIds: ['cut'])
    ]);
    expect((native.evidence['nativeRequestMoveBindings'] as List).single, {
      'baseId': 'fixture',
      'form': 1,
      'level': 1,
      'movePolicy': 'explicit',
      'moveIds': ['cut']
    });
    expect(
        () => const NativePsdkTrainerBundleBuilder().build(
                files: sources,
                requests: [
                  NativePsdkCatalogRequest(baseId: 'fixture', form: 1, level: 1)
                ]),
        _code('empty_moves'));
  });

  test(
      'keeps separate ordered move intentions for the same species form and level',
      () {
    final sources = _fixtureSources();
    _addNativeMove(sources, 'outside_cut');
    final requests = [
      NativePsdkCatalogRequest(baseId: 'fixture', form: 1, level: 5),
      NativePsdkCatalogRequest(
          baseId: 'fixture',
          form: 1,
          level: 5,
          explicitMoveIds: ['cut', 'outside_cut']),
      NativePsdkCatalogRequest(
          baseId: 'fixture',
          form: 1,
          level: 5,
          explicitMoveIds: ['outside_cut', 'cut']),
    ];
    final native = const NativePsdkTrainerBundleBuilder()
        .build(files: sources, requests: requests.reversed.toList());
    expect(native.evidence['catalogRequests'],
        requests.map((r) => r.toJson()).toList());
    expect(native.evidence['nativeRequestMoveBindings'], [
      {
        'baseId': 'fixture',
        'form': 1,
        'level': 5,
        'movePolicy': 'nativeDefaults',
        'moveIds': ['cut']
      },
      {
        'baseId': 'fixture',
        'form': 1,
        'level': 5,
        'movePolicy': 'explicit',
        'moveIds': ['cut', 'outside_cut']
      },
      {
        'baseId': 'fixture',
        'form': 1,
        'level': 5,
        'movePolicy': 'explicit',
        'moveIds': ['outside_cut', 'cut']
      },
    ]);
    expect(
        () => const NativePsdkTrainerBundleBuilder()
            .build(files: sources, requests: [...requests, requests.last]),
        _code('duplicate_request'));
  });

  test('rejects invalid and ambiguous requests before output', () {
    for (final raw in <Map<String, dynamic>>[
      {'baseId': '', 'form': 0, 'level': 1},
      {'baseId': '../fixture', 'form': 0, 'level': 1},
      {'baseId': 'FIXTURE', 'form': 0, 'level': 1},
      {'baseId': 'fixture', 'form': -1, 'level': 1},
      {'baseId': 'fixture', 'form': 0.5, 'level': 1},
      {'baseId': 'fixture', 'form': 0, 'level': 0},
      {'baseId': 'fixture', 'form': 0, 'level': 101},
      {'baseId': 'fixture', 'form': 0, 'level': 1, 'explicitMoveIds': []},
      {'baseId': 'fixture', 'form': 0, 'level': 1, 'explicitMoveIds': null},
      {
        'baseId': 'fixture',
        'form': 0,
        'level': 1,
        'explicitMoveIds': ['cut', 'cut']
      },
      {
        'baseId': 'fixture',
        'form': 0,
        'level': 1,
        'explicitMoveIds': ['../cut']
      },
      {
        'baseId': 'fixture',
        'form': 0,
        'level': 1,
        'explicitMoveIds': ['a', 'b', 'c', 'd', 'e']
      },
      {'baseId': 'fixture', 'form': 0, 'level': 1, 'unexpected': true},
    ]) {
      expect(() => NativePsdkCatalogRequest.fromJson(raw),
          _code('request_invalid'));
    }
    final sources = _fixtureSources();
    final request =
        NativePsdkCatalogRequest(baseId: 'fixture', form: 0, level: 1);
    expect(
        () => const NativePsdkTrainerBundleBuilder()
            .build(files: sources, requests: []),
        _code('request_invalid'));
    expect(
        () => const NativePsdkTrainerBundleBuilder()
            .build(files: sources, requests: [request, request]),
        _code('duplicate_request'));
    expect(
        () => const NativePsdkTrainerBundleBuilder().build(
                files: sources,
                requests: [
                  NativePsdkCatalogRequest(baseId: 'fixture', form: 2, level: 1)
                ]),
        _code('form_missing'));
    expect(
        () => const NativePsdkTrainerBundleBuilder()
                .build(files: sources, requests: [
              NativePsdkCatalogRequest(
                  baseId: 'fixture',
                  form: 0,
                  level: 1,
                  explicitMoveIds: ['missing_move'])
            ]),
        _code('source_missing:Data/Studio/moves/missing_move.json'));
  });

  test('closes evolution baby and known-move prerequisites without any roster',
      () {
    final sources = _fixtureSources();
    _addNativeMove(sources, 'evolution_cut');
    final first =
        jsonDecode(utf8.decode(sources.first.bytes)) as Map<String, dynamic>;
    final baby = jsonDecode(jsonEncode(first)) as Map<String, dynamic>;
    baby['id'] = 16;
    baby['dbSymbol'] = 'baby';
    sources.add(_source('Data/Studio/pokemon/baby.json', baby));
    _mutateSource(sources, 'Data/Studio/pokemon/fixture.json', (raw) {
      final form = (raw['forms'] as List).first as Map;
      form['babyDbSymbol'] = 'baby';
      form['babyForm'] = 1;
      form['evolutions'] = [
        {
          'dbSymbol': 'baby',
          'form': 1,
          'conditions': [
            {'type': 'skill1', 'value': 'evolution_cut'}
          ]
        }
      ];
    });
    final native = const NativePsdkTrainerBundleBuilder().build(
        files: sources,
        requests: [
          NativePsdkCatalogRequest(baseId: 'fixture', form: 0, level: 1)
        ]);
    expect(native.speciesById.keys,
        ['baby', 'baby_form1', 'fixture', 'fixture_form1']);
    expect(native.movesById.keys, ['cut', 'evolution_cut']);
    expect(
        native
            .evolutionsBySpeciesId['fixture']!.evolutions.single.requiredMoveId,
        'evolution_cut');
    expect(native.evidence.containsKey('sourceTrainerRosters'), isFalse);
    _mutateSource(
        sources,
        'Data/Studio/pokemon/fixture.json',
        (raw) => (((raw['forms'] as List).first as Map)['evolutions'] as List)
            .cast<Map>()
            .single['form'] = 2);
    expect(
        () => const NativePsdkTrainerBundleBuilder().build(
                files: sources,
                requests: [
                  NativePsdkCatalogRequest(baseId: 'fixture', form: 0, level: 1)
                ]),
        _code('form_missing'));
  });

  test('rejects duplicate native concrete forms and source witnesses', () {
    final sources = _fixtureSources();
    expect(
        () => const NativePsdkTrainerBundleBuilder().build(files: [
              ...sources,
              sources.first
            ], requests: [
              NativePsdkCatalogRequest(baseId: 'fixture', form: 0, level: 1)
            ]),
        _code('duplicate_source'));
    _mutateSource(sources, 'Data/Studio/pokemon/fixture.json',
        (raw) => ((raw['forms'] as List)[1] as Map)['form'] = 0);
    expect(
        () => const NativePsdkTrainerBundleBuilder().build(
                files: sources,
                requests: [
                  NativePsdkCatalogRequest(baseId: 'fixture', form: 0, level: 1)
                ]),
        _code('form_ambiguous'));
  });

  test('enforces independent request base closure form move and witness quotas',
      () {
    final request =
        NativePsdkCatalogRequest(baseId: 'fixture', form: 0, level: 1);
    final sources = _fixtureSources();
    expect(
        () => const NativePsdkTrainerBundleBuilder()
            .build(files: sources, requests: List.filled(257, request)),
        _code('request_quota'));
    expect(
        () => const NativePsdkTrainerBundleBuilder()
                .build(files: sources, requests: [
              for (var i = 0; i < 65; i++)
                NativePsdkCatalogRequest(
                    baseId: 'fixture_$i', form: 0, level: 1)
            ]),
        _code('requested_base_quota'));
    expect(
        () => const NativePsdkTrainerBundleBuilder().build(
            files: List.filled(2049, sources.first), requests: [request]),
        _code('source_file_quota'));
    final forms = _fixtureSources();
    _mutateSource(forms, 'Data/Studio/pokemon/fixture.json', (raw) {
      final template = (raw['forms'] as List).first as Map;
      raw['forms'] = [
        for (var i = 0; i < 129; i++) {...template, 'form': i}
      ];
    });
    expect(
        () => const NativePsdkTrainerBundleBuilder()
            .build(files: forms, requests: [request]),
        _code('form_quota'));
    final moves = _fixtureSources();
    _mutateSource(
        moves,
        'Data/Studio/pokemon/fixture.json',
        (raw) => ((raw['forms'] as List).first as Map)['moveSet'] = [
              for (var i = 0; i < 512; i++)
                {'klass': 'LevelLearnableMove', 'move': 'move_$i', 'level': 1}
            ]);
    expect(
        () => const NativePsdkTrainerBundleBuilder()
            .build(files: moves, requests: [request]),
        _code('move_quota'));
    final closure = _fixtureSources();
    _mutateSource(
        closure,
        'Data/Studio/pokemon/fixture.json',
        (raw) => ((raw['forms'] as List).first as Map)['evolutions'] = [
              for (var i = 0; i < 64; i++)
                {'dbSymbol': 'target_$i', 'form': 0, 'conditions': []}
            ]);
    expect(
        () => const NativePsdkTrainerBundleBuilder()
            .build(files: closure, requests: [request]),
        _code('species_closure_quota'));
  });

  test(
      'preserves the complete native move signature for explicit and progression data',
      () {
    final sources = _fixtureSources();
    _addNativeMove(sources, 'signature_move', level: 20);
    _mutateSource(sources, 'Data/Studio/moves/signature_move.json', (raw) {
      raw.addAll({
        'battleEngineMethod': 'native_unimplemented_method',
        'name': {'en': 'Native Signature', 'fr': 'Signature native'},
        'type': 'fire',
        'category': 'special',
        'power': 77,
        'accuracy': 83,
        'pp': 13,
        'priority': -2,
        'movecriticalRate': 3,
        'battleEngineAimedTarget': 'any_other_pokemon',
        'effectChance': 37,
        'battleStageMod': [
          {'battleStage': 'ATS_STAGE', 'modificator': 2, 'targetScope': 'self'}
        ],
        'moveStatus': [
          {'status': 'burn', 'luckRate': 19}
        ],
      });
      for (final flag in [
        'isDirect',
        'isBlocable',
        'isMirrorMove',
        'isGravity',
        'isPunch',
        'isSoundAttack',
        'isSlicingAttack',
        'isWind',
        'isHeal',
        'isBite',
        'isPulse',
        'isPowder',
        'isDance',
        'isBallistics',
        'isUnfreeze',
        'isAuthentic'
      ]) {
        raw[flag] = true;
      }
    });
    final native =
        const NativePsdkTrainerBundleBuilder().build(files: sources, requests: [
      NativePsdkCatalogRequest(
          baseId: 'fixture',
          form: 1,
          level: 1,
          explicitMoveIds: ['signature_move'])
    ]);
    final expected = PokemonMove(
        id: 'signature_move',
        name: 'Native Signature',
        names: {'en': 'Native Signature', 'fr': 'Signature native'},
        source: 'pokemon_sdk_studio',
        type: 'fire',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.any,
        basePower: 77,
        accuracy: const PokemonMoveAccuracy.percent(value: 83),
        pp: 13,
        priority: -2,
        critRatio: 3,
        flags: const [
          PokemonMoveFlag.contact,
          PokemonMoveFlag.protect,
          PokemonMoveFlag.mirror,
          PokemonMoveFlag.gravity,
          PokemonMoveFlag.punch,
          PokemonMoveFlag.sound,
          PokemonMoveFlag.slicing,
          PokemonMoveFlag.wind,
          PokemonMoveFlag.heal,
          PokemonMoveFlag.bite,
          PokemonMoveFlag.pulse,
          PokemonMoveFlag.powder,
          PokemonMoveFlag.dance,
          PokemonMoveFlag.bullet,
          PokemonMoveFlag.defrost,
          PokemonMoveFlag.bypassSubstitute,
        ],
        effects: const [
          PokemonMoveEffect.modifyStats(
              targetScope: PokemonMoveEffectTargetScope.self,
              chance: 37,
              stageChanges: [
                PokemonMoveStatStageChange(
                    stat: PokemonMoveStatId.specialAttack, stages: 2)
              ]),
          PokemonMoveEffect.applyStatus(statusId: 'burn', chance: 19),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
        unsupportedReasons: const ['psdk_method:native_unimplemented_method']);
    expect(native.movesById['signature_move']!.toJson(), expected.toJson());
    final entry = native.catalogs['moves']!.entries
        .singleWhere((move) => move['id'] == 'signature_move');
    expect(entry['battleEngineMethod'], 'native_unimplemented_method');
    expect((entry['sourceRefs'] as Map)['psdkBattleEngineMethod'],
        'native_unimplemented_method');
    expect(native.evidence['nativeMoveDataFidelityOnly'], isTrue);
    expect(native.evidence['activationRequiresExactRuntimeMoveQualification'],
        isTrue);
    expect(native.evidence['runtimeBattleBuilderQualified'], isFalse);
  });

  test(
      'accepts exact request form move and source limits without raising bounds',
      () {
    final sources = _fixtureSources();
    final move = jsonDecode(utf8.decode(sources
        .singleWhere(
            (source) => source.relativePath == 'Data/Studio/moves/cut.json')
        .bytes)) as Map<String, dynamic>;
    for (var i = 0; i < 511; i++) {
      sources.add(_source('Data/Studio/moves/bounded_$i.json',
          {...move, 'id': i + 1000, 'dbSymbol': 'bounded_$i'}));
    }
    _mutateSource(sources, 'Data/Studio/pokemon/fixture.json', (raw) {
      final template = (raw['forms'] as List).first as Map;
      raw['forms'] = [
        for (var i = 0; i < 128; i++)
          {
            ...template,
            'form': i,
            'moveSet': [
              {'klass': 'LevelLearnableMove', 'move': 'cut', 'level': 1},
              if (i == 0)
                for (var m = 0; m < 511; m++)
                  {'klass': 'TechLearnableMove', 'move': 'bounded_$m'}
            ]
          }
      ];
    });
    for (var i = sources.length; i < 2048; i++) {
      sources.add(_source(
          'Data/Studio/abilities/unused_$i.json', {'dbSymbol': 'unused_$i'}));
    }
    final requests = [
      for (var form = 0; form < 128; form++)
        for (var level = 1; level <= 2; level++)
          NativePsdkCatalogRequest(baseId: 'fixture', form: form, level: level)
    ];
    final native = const NativePsdkTrainerBundleBuilder()
        .build(files: sources, requests: requests);
    expect(native.speciesById, hasLength(128));
    expect(native.movesById, hasLength(512));
    expect(native.evidence['catalogRequests'] as List, hasLength(256));
    expect((native.evidence['quotas'] as Map)['requestedBases'], 64);
  });

  test(
      'accepts exact base closure and total byte limits and rejects one extra byte',
      () {
    final sources = _fixtureSources();
    final template =
        jsonDecode(utf8.decode(sources.first.bytes)) as Map<String, dynamic>;
    sources.removeAt(0);
    for (var i = 0; i < 64; i++) {
      sources.add(_source('Data/Studio/pokemon/base_$i.json', {
        ...template,
        'id': i + 1000,
        'dbSymbol': 'base_$i',
        'forms': [(template['forms'] as List).first]
      }));
    }
    final requests = [
      for (var i = 0; i < 64; i++)
        NativePsdkCatalogRequest(baseId: 'base_$i', form: 0, level: 1)
    ];
    expect(
        const NativePsdkTrainerBundleBuilder()
            .build(files: sources, requests: requests)
            .speciesById,
        hasLength(64));
    final closureSources = sources.toList();
    _mutateSource(
        closureSources,
        'Data/Studio/pokemon/base_0.json',
        (raw) => ((raw['forms'] as List).first as Map)['evolutions'] = [
              for (var i = 1; i < 64; i++)
                {'dbSymbol': 'base_$i', 'form': 0, 'conditions': []}
            ]);
    expect(
        const NativePsdkTrainerBundleBuilder().build(
            files: closureSources, requests: [requests.first]).speciesById,
        hasLength(64));
    var remaining = 16777216 -
        sources.fold<int>(0, (sum, source) => sum + source.bytes.length);
    var index = 0;
    while (remaining > 0) {
      final size = remaining > 1048576 ? 1048576 : remaining;
      final bytes = List<int>.filled(size, 32);
      sources.add(NativePsdkTrainerSourceFile(
          relativePath: 'Data/Studio/abilities/padding_${index++}.json',
          sha256: Sha256Hash(crypto.sha256.convert(bytes).toString()),
          bytes: bytes));
      remaining -= size;
    }
    expect(
        const NativePsdkTrainerBundleBuilder()
            .build(files: sources, requests: requests)
            .speciesById,
        hasLength(64));
    final byte = [32];
    final oneMore = NativePsdkTrainerSourceFile(
        relativePath: 'Data/Studio/abilities/padding_extra.json',
        sha256: Sha256Hash(crypto.sha256.convert(byte).toString()),
        bytes: byte);
    expect(
        () => const NativePsdkTrainerBundleBuilder()
            .build(files: [...sources, oneMore], requests: requests),
        _code('source_bytes_quota'));
    final oversized = List<int>.filled(1048577, 32);
    expect(
        () => NativePsdkTrainerSourceFile(
            relativePath: 'Data/Studio/abilities/oversized.json',
            sha256: Sha256Hash(crypto.sha256.convert(oversized).toString()),
            bytes: oversized),
        _code('source_witness'));
  });

  test('generic request recipe writes deterministically without trainer PBS',
      () async {
    final temp =
        await Directory.systemTemp.createTemp('native_catalog_recipe_');
    addTearDown(() => temp.delete(recursive: true));
    final root = Directory('${temp.path}/reference');
    for (final source in _fixtureSources()) {
      final file = File('${root.path}/${source.relativePath}');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(source.bytes);
    }
    final requestFile = File('${temp.path}/requests.json');
    final output = File('${temp.path}/bundle.json');
    final dartOutput = File('${temp.path}/bundle.dart');
    Future<ProcessResult> run() => Process.run(
        'dart',
        [
          'run',
          'tool/build_native_psdk_trainer_bundle.dart',
          '--catalog-requests',
          root.path,
          requestFile.path,
          output.path,
          dartOutput.path
        ],
        workingDirectory: Directory.current.path);
    final rows = [
      {'baseId': 'fixture', 'form': 0, 'level': 1},
      {
        'baseId': 'fixture',
        'form': 1,
        'level': 2,
        'explicitMoveIds': ['cut']
      }
    ];
    await requestFile.writeAsString(jsonEncode(
        {'kind': 'nativePsdkCatalogRequests', 'version': 1, 'requests': rows}));
    final first = await run();
    expect(first.exitCode, 0, reason: '${first.stdout} ${first.stderr}');
    final bytes = await output.readAsBytes();
    final native = NativePsdkTrainerBundle.fromJson(
        jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>);
    expect(native.evidence.containsKey('sourceTrainerRosters'), isFalse);
    await requestFile.writeAsString(jsonEncode({
      'kind': 'nativePsdkCatalogRequests',
      'version': 1,
      'requests': rows.reversed.toList()
    }));
    final second = await run();
    expect(second.exitCode, 0, reason: '${second.stdout} ${second.stderr}');
    expect(await output.readAsBytes(), bytes);
    expect(await dartOutput.readAsString(),
        "const nativePsdkTrainerBundleJson = r'''${utf8.decode(bytes)}''';\n");
    await requestFile.writeAsString(jsonEncode({
      'kind': 'nativePsdkCatalogRequests',
      'version': 1,
      'requests': [...rows, rows.first]
    }));
    final invalid = await run();
    expect(invalid.exitCode, isNot(0));
    expect(await output.readAsBytes(), bytes);
  }, timeout: const Timeout(Duration(seconds: 60)));

  test('embedded reference matches the rebuildable asset exactly', () async {
    final asset =
        await File('assets/native_psdk_trainer_bundle.json').readAsString();
    expect(asset, nativePsdkTrainerBundleJson);
    final builtin = NativePsdkTrainerBundle.builtin();
    final restored = NativePsdkTrainerBundle.fromJson(
        jsonDecode(jsonEncode(builtin.toJson())) as Map<String, dynamic>);
    expect(
        canonicalHashOf(builtin.toJson()), canonicalHashOf(restored.toJson()));
    final paths = (builtin.evidence['sources'] as List).cast<Map>();
    expect(paths, hasLength(583));
    expect(
        paths.every(
            (source) => !(source['relativePath'] as String).startsWith('/')),
        isTrue);
    expect(
        paths.every((source) => !source.containsKey('absolutePath')), isTrue);
  });

  test('preserves the qualified native documents and trainer recipe', () {
    final json =
        jsonDecode(jsonEncode(NativePsdkTrainerBundle.builtin().toJson()))
            as Map<String, dynamic>;
    json.remove('version');
    for (final species in (json['species'] as List).cast<Map>()) {
      (species['breeding'] as Map).remove('genderRatio');
    }
    (json['catalogs'] as List)
        .removeWhere((catalog) => (catalog as Map)['catalog'] == 'natures');
    final evidence = json['evidence'] as Map;
    for (final field in [
      'genderRatioOracle',
      'natureStatOracle',
      'natureEffectPolicy'
    ]) {
      evidence.remove(field);
    }
    (evidence['sources'] as List).removeWhere((source) =>
        ((source as Map)['relativePath'] as String)
            .startsWith('Data/Studio/natures/'));
    expect(canonicalHashOf(json).value,
        '699bc40673918781767d199381f1113486e77c204fa9d8e12e5c08db443af069');
  });

  test('rejects duplicate documents and incomplete type charts', () {
    final original = NativePsdkTrainerBundle.builtin().toJson();
    final duplicate = jsonDecode(jsonEncode(original)) as Map<String, dynamic>;
    (duplicate['species'] as List).add((duplicate['species'] as List).first);
    expect(
        () => NativePsdkTrainerBundle.fromJson(duplicate),
        throwsA(isA<ContractError>().having((error) => error.code, 'code',
            'native_trainer.duplicate_species')));
    final missing = jsonDecode(jsonEncode(original)) as Map<String, dynamic>;
    final types = (missing['catalogs'] as List)
        .cast<Map>()
        .singleWhere((catalog) => catalog['catalog'] == 'types');
    (types['entries'] as List).removeLast();
    expect(
        () => NativePsdkTrainerBundle.fromJson(missing),
        throwsA(isA<ContractError>().having(
            (error) => error.code, 'code', 'native_trainer.type_closure')));
  });

  test('maps every native form female rate to canonical gender weights', () {
    for (final (rate, expected) in <(num, Map<String, double>)>[
      (-1, {'genderless': 1}),
      (0, {'male': 100, 'female': 0}),
      (12.5, {'male': 87.5, 'female': 12.5}),
      (50, {'male': 50, 'female': 50}),
      (100, {'male': 0, 'female': 100}),
    ]) {
      final bundle = _buildFixture(femaleRate: rate);
      expect(bundle.speciesById['fixture']!.breeding.genderRatio, expected);
      expect(bundle.speciesById['fixture_form1']!.breeding.genderRatio,
          {'male': 75, 'female': 25});
    }
  });

  test('rejects missing and invalid native form female rates before output',
      () {
    for (final invalid in [null, '50', -2, -0.5, 100.1, 101]) {
      expect(() => _buildFixture(femaleRate: invalid), _code('female_rate'));
    }
    for (final invalid in ['1e400', '-1e400']) {
      final sources = _fixtureSources();
      final source = sources.first;
      final text = utf8
          .decode(source.bytes)
          .replaceFirst('"femaleRate":50', '"femaleRate":$invalid');
      final bytes = utf8.encode(text);
      sources[0] = NativePsdkTrainerSourceFile(
          relativePath: source.relativePath,
          sha256: Sha256Hash(crypto.sha256.convert(bytes).toString()),
          bytes: bytes);
      expect(
          () => const NativePsdkTrainerBundleBuilder()
                  .build(files: sources, requests: [
                NativePsdkCatalogRequest(baseId: 'fixture', form: 0, level: 1)
              ]),
          _code('female_rate'));
    }
  });

  test('rejects a missing female rate on an alternate form', () {
    final sources = _fixtureSources();
    _mutateSource(sources, 'Data/Studio/pokemon/fixture.json',
        (raw) => ((raw['forms'] as List).last as Map).remove('femaleRate'));
    expect(
        () => const NativePsdkTrainerBundleBuilder().build(
                files: sources,
                requests: [
                  NativePsdkCatalogRequest(baseId: 'fixture', form: 0, level: 1)
                ]),
        _code('female_rate'));
  });

  test('publishes all native nature effects with exact source witnesses', () {
    final bundle = _buildFixture();
    final entries = bundle.catalogs['natures']!.entries;
    expect(entries.map((entry) => entry['id']),
        orderedEquals(_natureRows.map((row) => row.$1).toList()..sort()));
    final neutral = <String>[];
    for (final entry in entries) {
      final row = _natureRows.singleWhere((row) => row.$1 == entry['id']);
      const stats = [
        'attack',
        'defense',
        'speed',
        'specialAttack',
        'specialDefense'
      ];
      expect(entry['increasedStat'],
          row.$2.contains(110) ? stats[row.$2.indexOf(110)] : null);
      expect(entry['decreasedStat'],
          row.$2.contains(90) ? stats[row.$2.indexOf(90)] : null);
      if (entry['increasedStat'] == null) neutral.add(entry['id'] as String);
    }
    expect(neutral, ['bashful', 'docile', 'hardy', 'quirky', 'serious']);
    final files = _fixtureSources();
    final witnesses = (bundle.evidence['sources'] as List).cast<Map>();
    for (final source in files.where(
        (source) => source.relativePath.startsWith('Data/Studio/natures/'))) {
      expect(
          witnesses
              .singleWhere((row) => row['relativePath'] == source.relativePath),
          source.evidence);
    }
  });

  test('rejects missing or noncanonical native nature source data', () {
    for (final mutation in <void Function(List<NativePsdkTrainerSourceFile>)>[
      (sources) => sources.removeWhere((source) =>
          source.relativePath == 'Data/Studio/natures/adamant.json'),
      (sources) => _mutateSource(sources, 'Data/Studio/natures/adamant.json',
          (raw) => (raw['stats'] as Map).remove('ats')),
      (sources) => _mutateSource(sources, 'Data/Studio/natures/adamant.json',
          (raw) => (raw['stats'] as Map)['ats'] = 100),
      (sources) => _mutateSource(
          sources, 'Data/Studio/natures/adamant.json', (raw) => raw['id'] = 4),
      (sources) => _mutateSource(sources, 'Data/Studio/natures/adamant.json',
          (raw) => raw['klass'] = 'Move'),
      (sources) => _mutateSource(sources, 'Data/Studio/natures/adamant.json',
          (raw) => raw['dbSymbol'] = 'jolly'),
      (sources) => sources.add(sources.singleWhere((source) =>
          source.relativePath == 'Data/Studio/natures/adamant.json')),
    ]) {
      final sources = _fixtureSources();
      mutation(sources);
      expect(
          () => const NativePsdkTrainerBundleBuilder()
                  .build(files: sources, requests: [
                NativePsdkCatalogRequest(baseId: 'fixture', form: 0, level: 1)
              ]),
          throwsA(isA<ContractError>()));
    }
  });

  test('rejects incoherent canonical bundle gender ratios', () {
    for (final ratio in <Map<String, Object?>>[
      {},
      {'genderless': 1, 'male': 100},
      {'male': 50},
      {'male': 60, 'female': 50},
      {'male': -1, 'female': 101},
      {'male': double.nan, 'female': 50},
      {'male': 50, 'female': double.infinity},
      {'genderless': 100},
      {'unknown': 100},
    ]) {
      final json = _buildFixture().toJson();
      final first = (json['species'] as List).first as Map;
      (first['breeding'] as Map)['genderRatio'] = ratio;
      expect(
          () => NativePsdkTrainerBundle.fromJson(json), _code('gender_ratio'));
    }
  });

  test('rejects incomplete duplicate or tampered bundle nature effects', () {
    for (final mutation in <void Function(Map<String, Object?>)>[
      (json) => _natureEntries(json).removeLast(),
      (json) => _natureEntries(json).add(_natureEntries(json).first),
      (json) => (_natureEntries(json).first as Map)['increasedStat'] = 'speed',
      (json) => (_natureEntries(json).first as Map).remove('decreasedStat'),
      (json) => _natureEntries(json).clear(),
      (json) => (_natureEntries(json).first as Map)['id'] = 'invented',
    ]) {
      final json = jsonDecode(jsonEncode(_buildFixture().toJson()))
          as Map<String, dynamic>;
      mutation(json);
      expect(() => NativePsdkTrainerBundle.fromJson(json),
          throwsA(isA<ContractError>()));
    }
  });

  test('rejects obsolete bundle contracts and missing nature witnesses', () {
    final obsolete = _buildFixture().toJson()..['version'] = 1;
    expect(() => NativePsdkTrainerBundle.fromJson(obsolete),
        _code('bundle_version'));
    final missing = jsonDecode(jsonEncode(_buildFixture().toJson()))
        as Map<String, dynamic>;
    ((missing['evidence'] as Map)['sources'] as List).removeWhere((source) =>
        (source as Map)['relativePath'] == 'Data/Studio/natures/jolly.json');
    expect(() => NativePsdkTrainerBundle.fromJson(missing),
        _code('nature_source_witness'));
  });

  test('builds deterministic documents from unordered exact witnesses', () {
    final files = _fixtureSources();
    final ordered = const NativePsdkTrainerBundleBuilder().build(
        files: files,
        requests: [
          NativePsdkCatalogRequest(baseId: 'fixture', form: 0, level: 1)
        ]);
    final reversed = const NativePsdkTrainerBundleBuilder().build(
        files: files.reversed.toList(),
        requests: [
          NativePsdkCatalogRequest(baseId: 'fixture', form: 0, level: 1)
        ]);
    expect(
        canonicalHashOf(ordered.toJson()), canonicalHashOf(reversed.toJson()));
    expect(ordered.movesById.keys, ['cut']);
    expect(ordered.evidence['nativeBattleDefaultMoveIds'], ['cut']);
    expect(ordered.speciesById['fixture']!.baseStats.toJson(), {
      'hp': 65,
      'atk': 90,
      'def': 40,
      'spa': 45,
      'spd': 80,
      'spe': 75,
      'bst': 395
    });
    expect(ordered.learnsetsBySpeciesId['fixture']!.startingMoves, ['cut']);
  });

  final sourceRoot = Platform.environment['AVELUNE_NATIVE_PSDK_REFERENCE_ROOT'];
  test('rebuilds the same species, moves and charts from attested PSDK JSON',
      () async {
    final builtin = NativePsdkTrainerBundle.builtin();
    final files = <NativePsdkTrainerSourceFile>[];
    for (final raw in (builtin.evidence['sources'] as List).cast<Map>()) {
      final path = raw['relativePath'] as String;
      final bytes = await File('$sourceRoot/$path').readAsBytes();
      expect(crypto.sha256.convert(bytes).toString(), raw['sha256']);
      files.add(NativePsdkTrainerSourceFile(
          relativePath: path,
          sha256: Sha256Hash(raw['sha256'] as String),
          bytes: bytes));
    }
    final levels = (builtin.evidence['requestedLevels'] as Map).map(
        (key, value) =>
            MapEntry(key as String, (value as List).cast<int>().toSet()));
    final rebuilt =
        const NativePsdkTrainerBundleBuilder().build(files: files, requests: [
      for (final entry in levels.entries)
        for (final level in entry.value)
          NativePsdkCatalogRequest(baseId: entry.key, form: 0, level: level)
    ]);
    final expectedSpecies = (builtin.toJson()['species'] as List).cast<Map>();
    for (final species in expectedSpecies) {
      species['names'] = <String, String>{};
    }
    expect(rebuilt.toJson()['species'], expectedSpecies);
    expect(rebuilt.toJson()['sourceLearnsets'],
        builtin.toJson()['sourceLearnsets']);
    final expectedCatalogs = (builtin.toJson()['catalogs'] as List).cast<Map>();
    final moves = expectedCatalogs.singleWhere((c) => c['catalog'] == 'moves');
    for (final move in (moves['entries'] as List).cast<Map>()) {
      final reasons = move['unsupportedReasons'] as List;
      if (reasons.contains('native_roster_unused_move_unqualified')) {
        move['unsupportedReasons'] = reasons
            .where(
                (reason) => reason != 'native_roster_unused_move_unqualified')
            .toList();
        move['engineSupportLevel'] = 'structured_partial';
      }
    }
    expect(rebuilt.toJson()['catalogs'], expectedCatalogs);
    expect(rebuilt.evidence['sources'], builtin.evidence['sources']);
  },
      skip: sourceRoot == null
          ? 'Requires the optional read-only PSDK reference root.'
          : false);
}

Matcher _code(String suffix) => throwsA(isA<ContractError>()
    .having((error) => error.code, 'code', 'native_trainer.$suffix'));

List<dynamic> _natureEntries(Map<String, Object?> json) =>
    ((json['catalogs'] as List).cast<Map>().singleWhere(
        (catalog) => catalog['catalog'] == 'natures')['entries'] as List);

NativePsdkTrainerBundle _buildFixture({Object? femaleRate = 50}) =>
    const NativePsdkTrainerBundleBuilder().build(
        files: _fixtureSources(femaleRate: femaleRate),
        requests: [
          NativePsdkCatalogRequest(baseId: 'fixture', form: 0, level: 1)
        ]);

NativePsdkTrainerSourceFile _source(String path, Object raw) {
  final bytes = utf8.encode(jsonEncode(raw));
  return NativePsdkTrainerSourceFile(
      relativePath: path,
      sha256: Sha256Hash(crypto.sha256.convert(bytes).toString()),
      bytes: bytes);
}

void _mutateSource(List<NativePsdkTrainerSourceFile> sources, String path,
    void Function(Map<String, dynamic>) mutate) {
  final index = sources.indexWhere((source) => source.relativePath == path);
  final raw =
      jsonDecode(utf8.decode(sources[index].bytes)) as Map<String, dynamic>;
  mutate(raw);
  sources[index] = _source(path, raw);
}

List<NativePsdkTrainerSourceFile> _fixtureSources({Object? femaleRate = 50}) {
  Map<String, Object?> form(int number, Object? rate) => {
        'form': number,
        'femaleRate': rate,
        'type1': 'bug',
        'type2': 'poison',
        'baseHp': 65,
        'baseAtk': 90,
        'baseDfe': 40,
        'baseAts': 45,
        'baseDfs': 80,
        'baseSpd': 75,
        'height': 1,
        'weight': 29.5,
        'experienceType': 1,
        'baseExperience': 178,
        'catchRate': 45,
        'baseLoyalty': 70,
        'abilities': ['swarm', 'swarm', 'swarm'],
        'moveSet': [
          {'klass': 'LevelLearnableMove', 'move': 'cut', 'level': 1}
        ],
        'evolutions': [],
        'resources': {'front': 'fixture', 'back': 'fixture'},
      };
  final cut = base64Decode(
      'ew0KICAia2xhc3MiOiAiTW92ZSIsDQogICJpZCI6IDE1LA0KICAiZGJTeW1ib2wiOiAiY3V0IiwNCiAgIm1hcFVzZSI6IDIxLA0KICAiYmF0dGxlRW5naW5lTWV0aG9kIjogInNfYmFzaWMiLA0KICAidHlwZSI6ICJub3JtYWwiLA0KICAicG93ZXIiOiA1MCwNCiAgImFjY3VyYWN5IjogOTUsDQogICJwcCI6IDMwLA0KICAiY2F0ZWdvcnkiOiAicGh5c2ljYWwiLA0KICAibW92ZWNyaXRpY2FsUmF0ZSI6IDEsDQogICJwcmlvcml0eSI6IDAsDQogICJpc0F1dGhlbnRpYyI6IGZhbHNlLA0KICAiaXNCYWxsaXN0aWNzIjogZmFsc2UsDQogICJpc0JpdGUiOiBmYWxzZSwNCiAgImlzQmxvY2FibGUiOiB0cnVlLA0KICAiaXNDaGFyZ2UiOiBmYWxzZSwNCiAgImlzRGFuY2UiOiBmYWxzZSwNCiAgImlzRGlyZWN0IjogdHJ1ZSwNCiAgImlzRWZmZWN0Q2hhbmNlIjogZmFsc2UsDQogICJpc0dyYXZpdHkiOiBmYWxzZSwNCiAgImlzSGVhbCI6IGZhbHNlLA0KICAiaXNLaW5nUm9ja1V0aWxpdHkiOiB0cnVlLA0KICAiaXNNYWdpY0NvYXRBZmZlY3RlZCI6IGZhbHNlLA0KICAiaXNNZW50YWwiOiBmYWxzZSwNCiAgImlzTWlycm9yTW92ZSI6IHRydWUsDQogICJpc05vblNreUJhdHRsZSI6IGZhbHNlLA0KICAiaXNQb3dkZXIiOiBmYWxzZSwNCiAgImlzUHVsc2UiOiBmYWxzZSwNCiAgImlzUHVuY2giOiBmYWxzZSwNCiAgImlzUmVjaGFyZ2UiOiBmYWxzZSwNCiAgImlzU25hdGNoYWJsZSI6IGZhbHNlLA0KICAiaXNTb3VuZEF0dGFjayI6IGZhbHNlLA0KICAiaXNTbGljaW5nQXR0YWNrIjogZmFsc2UsDQogICJpc1VuZnJlZXplIjogZmFsc2UsDQogICJpc1dpbmQiOiBmYWxzZSwNCiAgImJhdHRsZUVuZ2luZUFpbWVkVGFyZ2V0IjogImFkamFjZW50X3Bva2Vtb24iLA0KICAiYmF0dGxlU3RhZ2VNb2QiOiBbXSwNCiAgIm1vdmVTdGF0dXMiOiBbXSwNCiAgImVmZmVjdENoYW5jZSI6IDAsDQogICJjb25kaXRpb24iOiAiY29vbCIsDQogICJhcHBlYWwiOiA0LA0KICAiamFtIjogMCwNCiAgImNvbWJvTW92ZXMiOiBbXSwNCiAgImVmZmVjdFRhZ3MiOiBbXQ0KfQ==');
  final png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==');
  return [
    _source('Data/Studio/pokemon/fixture.json', {
      'klass': 'Specie',
      'id': 15,
      'dbSymbol': 'fixture',
      'forms': [form(0, femaleRate), form(1, 25)],
    }),
    NativePsdkTrainerSourceFile(
        relativePath: 'Data/Studio/moves/cut.json',
        sha256: Sha256Hash(crypto.sha256.convert(cut).toString()),
        bytes: cut),
    for (final side in ['front', 'back'])
      NativePsdkTrainerSourceFile(
          relativePath: 'graphics/pokedex/poke$side/fixture.png',
          sha256: Sha256Hash(crypto.sha256.convert(png).toString()),
          bytes: png),
    _source('Data/Studio/abilities/swarm.json',
        {'klass': 'Ability', 'id': 68, 'dbSymbol': 'swarm'}),
    for (final id in nativeTrainerTypeIds)
      _source('Data/Studio/types/$id.json', {'dbSymbol': id, 'damageTo': []}),
    for (var index = 0; index < _natureRows.length; index++)
      _source('Data/Studio/natures/${_natureRows[index].$1}.json', {
        'klass': 'Nature',
        'id': index,
        'dbSymbol': _natureRows[index].$1,
        'stats': {
          for (final (offset, stat)
              in ['atk', 'dfe', 'spd', 'ats', 'dfs'].indexed)
            stat: _natureRows[index].$2[offset],
        },
      }),
  ];
}

const _natureRows = <(String, List<int>)>[
  ('hardy', [100, 100, 100, 100, 100]),
  ('lonely', [110, 90, 100, 100, 100]),
  ('brave', [110, 100, 90, 100, 100]),
  ('adamant', [110, 100, 100, 90, 100]),
  ('naughty', [110, 100, 100, 100, 90]),
  ('bold', [90, 110, 100, 100, 100]),
  ('docile', [100, 100, 100, 100, 100]),
  ('relaxed', [100, 110, 90, 100, 100]),
  ('impish', [100, 110, 100, 90, 100]),
  ('lax', [100, 110, 100, 100, 90]),
  ('timid', [90, 100, 110, 100, 100]),
  ('hasty', [100, 90, 110, 100, 100]),
  ('serious', [100, 100, 100, 100, 100]),
  ('jolly', [100, 100, 110, 90, 100]),
  ('naive', [100, 100, 110, 100, 90]),
  ('modest', [90, 100, 100, 110, 100]),
  ('mild', [100, 90, 100, 110, 100]),
  ('quiet', [100, 100, 90, 110, 100]),
  ('bashful', [100, 100, 100, 100, 100]),
  ('rash', [100, 100, 100, 110, 90]),
  ('calm', [90, 100, 100, 100, 110]),
  ('gentle', [100, 90, 100, 100, 110]),
  ('sassy', [100, 100, 90, 100, 110]),
  ('careful', [100, 100, 100, 90, 110]),
  ('quirky', [100, 100, 100, 100, 100]),
];

void _addNativeMove(List<NativePsdkTrainerSourceFile> sources, String id,
    {int? level}) {
  final raw = jsonDecode(utf8.decode(sources
      .singleWhere(
          (source) => source.relativePath == 'Data/Studio/moves/cut.json')
      .bytes)) as Map<String, dynamic>;
  raw['id'] = 999;
  raw['dbSymbol'] = id;
  sources.add(_source('Data/Studio/moves/$id.json', raw));
  if (level != null) {
    _mutateSource(sources, 'Data/Studio/pokemon/fixture.json', (raw) {
      for (final form in (raw['forms'] as List).cast<Map>()) {
        (form['moveSet'] as List)
            .add({'klass': 'LevelLearnableMove', 'move': id, 'level': level});
      }
    });
  }
}
