import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';

import 'source_event_item_bindings.dart';

final class SourcePokedexRewardBinding {
  SourcePokedexRewardBinding._(
      {required this.range,
      required this.item,
      required this.archive,
      required this.itemArchive,
      required this.sourceSnapshotHash,
      required this.normalizationHash,
      required this.profileHash,
      required this.eventHash,
      required List<SourcePokedexRewardProgramNode> programs})
      : programs = List.unmodifiable(programs);

  final PokedexSpeciesRange range;
  final SourceEventItemBinding item;
  final SourceArchive archive, itemArchive;
  final Sha256Hash sourceSnapshotHash,
      normalizationHash,
      profileHash,
      eventHash;
  final List<SourcePokedexRewardProgramNode> programs;

  bool isBoundToEvent(
      {required NormalizedSourceProject source,
      required SourceEventAnalysis analysis,
      required SourceEventDefinition event}) {
    if (!analysis.profile.isQualified ||
        source.snapshot.canonicalHash != sourceSnapshotHash ||
        source.canonicalHash != normalizationHash ||
        analysis.profile.canonicalHash != profileHash ||
        event.sourceMapId != 102 ||
        event.sourceEventId != 10 ||
        canonicalHashOf(_eventFingerprint(event)) != eventHash) {
      return false;
    }
    final maps = source.maps.where((map) => map.map.sourceMapId == 102);
    if (maps.length != 1) {
      return false;
    }
    final originals =
        maps.single.map.events.where((event) => event.sourceEventId == 10);
    return originals.length == 1 &&
        programs.length == 2 &&
        programs.every((program) => program.isBoundToSourceEvent(
            source: source,
            profile: analysis.profile,
            sourceMapId: 102,
            event: originals.single));
  }

  Map<String, Object?> toJson() => {
        'kind': 'sourcePokedexRewardBinding',
        'version': 1,
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'normalizationHash': normalizationHash.value,
        'profileHash': profileHash.value,
        'eventHash': eventHash.value,
        'sourceDexIndex': 1,
        'nativeScope': range.key,
        'sourceRegionalDexFile': archive.files.values.single.entry.toJson(),
        'referenceSourceFileHash': _referenceRegionalDexHash,
        'sourceFileMatchesReference':
            archive.files.values.single.contentHash.value ==
                _referenceRegionalDexHash,
        'referenceMappingHash':
            '6dd419e2ee9bfa31eae4549a1a2a0329249d21f7b113d6f91e29b9e8d688e347',
        'referenceAuthority': 'psdkTestProjectCanonicalNationalDex',
        'regionalSpecies': [
          for (var index = 0; index < _sourceSymbols.length; index++)
            {
              'sourceSymbol': _sourceSymbols[index],
              'nativeId': _nativeIds[index],
              'nationalDex': index + 1
            }
        ],
        'sourcePrograms': programs.map((program) => program.toJson()).toList(),
        'sourceItemCatalog': item.toJson(),
        'nativeGrantScope': 'nativeAtomicUnitBagGrant',
        'sourceGiftPresentationParityQualified': false,
        'nativeHeldItemEvolutionEffectQualified': false,
        'nativeExecutionQualified': false,
        'fullSourceRewardParityQualified': false,
        'sourceScriptsExecuted': 0,
        'aiCalls': 0,
      };
}

final class SourcePokedexRewardBindingResolver {
  const SourcePokedexRewardBindingResolver();
  Future<SourcePokedexRewardBinding?> read(
      {required NormalizedSourceProject source,
      required SourceEventAnalysis analysis,
      required SourceFilePort files,
      ScanCancellation? cancellation}) async {
    cancellation?.check();
    if (source.snapshot.state != SourceScanState.complete ||
        analysis.profile.sourceSnapshotHash != source.snapshot.canonicalHash ||
        analysis.profile.normalizationHash != source.canonicalHash) {
      throw ContractError('events.pokedex_reward.source_binding', r'$',
          'Pokedex reward bindings require the exact complete source analysis.');
    }
    if (!analysis.profile.isQualified) {
      return null;
    }
    final event = analysis.eventAt(102, 10);
    if (event == null ||
        event.isQuarantined ||
        event.pages.length != 2 ||
        event.pages.any((page) =>
            page.body.nodes.length != 1 ||
            page.body.nodes.single is! SourcePokedexRewardProgramNode)) {
      return null;
    }
    final programs = event.pages
        .map((page) => page.body.nodes.single as SourcePokedexRewardProgramNode)
        .toList();
    final expected =
        SourceEventAnalyzer.forProject(source, profile: analysis.profile)
            .analyze()
            .eventAt(102, 10);
    if (expected == null ||
        canonicalJsonOf(_eventFingerprint(expected)) !=
            canonicalJsonOf(_eventFingerprint(event))) {
      return null;
    }
    const path = 'Data/regional_dexes.dat';
    final entries = source.snapshot.entries.where((entry) =>
        sourcePathCollisionKey(entry.relativePath) ==
        sourcePathCollisionKey(path));
    if (entries.length != 1 || entries.single.relativePath != path) {
      return null;
    }
    final entry = entries.single;
    const maxBytes = 1048576;
    if (entry.kind != SourceNodeKind.file ||
        entry.sha256 == null ||
        entry.byteLength <= 0 ||
        entry.byteLength > maxBytes) {
      return null;
    }
    final bytes = await files.read(entry.fileId);
    cancellation?.check();
    if (bytes.length != entry.byteLength ||
        bytes.any((byte) => byte < 0 || byte > 255) ||
        crypto.sha256.convert(bytes).toString() != entry.sha256!.value) {
      throw ContractError('events.pokedex_reward.source_changed', path,
          'Regional dex bytes differ from the complete source inventory.');
    }
    final archive = SourceArchive(
        limits: const SourceArchiveLimits(
            maxFiles: 1,
            maxFileBytes: maxBytes,
            maxTotalBytes: maxBytes,
            maxTotalNodes: 100000,
            maxTotalEntries: 100000,
            maxEncodedCodeUnits: 4194304,
            maxTotalLocationCodeUnits: 4194304,
            maxReferences: 16));
    final SourceArchivedFile file;
    try {
      file = archive.add(entry, bytes);
    } on ContractError catch (error) {
      if (['quota', 'limit', 'changed', 'hash'].any(error.code.contains)) {
        rethrow;
      }
      return null;
    }
    final document = file.document;
    final root = document.node(document.rootId);
    if (root.kind != MarshalKind.array ||
        root.elements.length < 2 ||
        root.elements.length > 32) {
      return null;
    }
    final region = document.node(root.elements[1]);
    if (region.kind != MarshalKind.array ||
        region.elements.length != _sourceSymbols.length) {
      return null;
    }
    for (var index = 0; index < _sourceSymbols.length; index++) {
      final species = document.node(region.elements[index]);
      if (species.kind != MarshalKind.symbol ||
          species.name != _sourceSymbols[index]) {
        return null;
      }
    }
    archive.seal();
    final SourceEventItemBindings items;
    try {
      items = await const SourceEventItemBindingResolver().read(
          snapshot: source.snapshot,
          files: files,
          symbols: const ['EVERSTONE'],
          eventProfile: analysis.profile,
          cancellation: cancellation);
    } on ContractError catch (error) {
      if (['quota', 'limit', 'changed', 'hash'].any(error.code.contains)) {
        rethrow;
      }
      return null;
    }
    final item = items.bindings['EVERSTONE'];
    if (item == null ||
        !item.pickupQualified ||
        item.isKeyItem ||
        item.isMachine ||
        item.sourceSnapshotHash != source.snapshot.canonicalHash) {
      return null;
    }
    final binding = SourcePokedexRewardBinding._(
        range: PokedexSpeciesRange(firstNationalDex: 1, lastNationalDex: 151),
        item: item,
        archive: archive,
        itemArchive: items.archive,
        sourceSnapshotHash: source.snapshot.canonicalHash,
        normalizationHash: source.canonicalHash,
        profileHash: analysis.profile.canonicalHash,
        eventHash: canonicalHashOf(_eventFingerprint(event)),
        programs: programs);
    return binding.isBoundToEvent(
            source: source, analysis: analysis, event: event)
        ? binding
        : null;
  }
}

const _referenceRegionalDexHash =
    '2fa70db52a28bff5eb4565a87b9344da48f0610e2da1bfff948343fecaa121ea';
const _sourceSymbols = [
  "BULBASAUR",
  "IVYSAUR",
  "VENUSAUR",
  "CHARMANDER",
  "CHARMELEON",
  "CHARIZARD",
  "SQUIRTLE",
  "WARTORTLE",
  "BLASTOISE",
  "CATERPIE",
  "METAPOD",
  "BUTTERFREE",
  "WEEDLE",
  "KAKUNA",
  "BEEDRILL",
  "PIDGEY",
  "PIDGEOTTO",
  "PIDGEOT",
  "RATTATA",
  "RATICATE",
  "SPEAROW",
  "FEAROW",
  "EKANS",
  "ARBOK",
  "PIKACHU",
  "RAICHU",
  "SANDSHREW",
  "SANDSLASH",
  "NIDORANfE",
  "NIDORINA",
  "NIDOQUEEN",
  "NIDORANmA",
  "NIDORINO",
  "NIDOKING",
  "CLEFAIRY",
  "CLEFABLE",
  "VULPIX",
  "NINETALES",
  "JIGGLYPUFF",
  "WIGGLYTUFF",
  "ZUBAT",
  "GOLBAT",
  "ODDISH",
  "GLOOM",
  "VILEPLUME",
  "PARAS",
  "PARASECT",
  "VENONAT",
  "VENOMOTH",
  "DIGLETT",
  "DUGTRIO",
  "MEOWTH",
  "PERSIAN",
  "PSYDUCK",
  "GOLDUCK",
  "MANKEY",
  "PRIMEAPE",
  "GROWLITHE",
  "ARCANINE",
  "POLIWAG",
  "POLIWHIRL",
  "POLIWRATH",
  "ABRA",
  "KADABRA",
  "ALAKAZAM",
  "MACHOP",
  "MACHOKE",
  "MACHAMP",
  "BELLSPROUT",
  "WEEPINBELL",
  "VICTREEBEL",
  "TENTACOOL",
  "TENTACRUEL",
  "GEODUDE",
  "GRAVELER",
  "GOLEM",
  "PONYTA",
  "RAPIDASH",
  "SLOWPOKE",
  "SLOWBRO",
  "MAGNEMITE",
  "MAGNETON",
  "FARFETCHD",
  "DODUO",
  "DODRIO",
  "SEEL",
  "DEWGONG",
  "GRIMER",
  "MUK",
  "SHELLDER",
  "CLOYSTER",
  "GASTLY",
  "HAUNTER",
  "GENGAR",
  "ONIX",
  "DROWZEE",
  "HYPNO",
  "KRABBY",
  "KINGLER",
  "VOLTORB",
  "ELECTRODE",
  "EXEGGCUTE",
  "EXEGGUTOR",
  "CUBONE",
  "MAROWAK",
  "HITMONLEE",
  "HITMONCHAN",
  "LICKITUNG",
  "KOFFING",
  "WEEZING",
  "RHYHORN",
  "RHYDON",
  "CHANSEY",
  "TANGELA",
  "KANGASKHAN",
  "HORSEA",
  "SEADRA",
  "GOLDEEN",
  "SEAKING",
  "STARYU",
  "STARMIE",
  "MRMIME",
  "SCYTHER",
  "JYNX",
  "ELECTABUZZ",
  "MAGMAR",
  "PINSIR",
  "TAUROS",
  "MAGIKARP",
  "GYARADOS",
  "LAPRAS",
  "DITTO",
  "EEVEE",
  "VAPOREON",
  "JOLTEON",
  "FLAREON",
  "PORYGON",
  "OMANYTE",
  "OMASTAR",
  "KABUTO",
  "KABUTOPS",
  "AERODACTYL",
  "SNORLAX",
  "ARTICUNO",
  "ZAPDOS",
  "MOLTRES",
  "DRATINI",
  "DRAGONAIR",
  "DRAGONITE",
  "MEWTWO",
  "MEW"
];
const _nativeIds = [
  "bulbasaur",
  "ivysaur",
  "venusaur",
  "charmander",
  "charmeleon",
  "charizard",
  "squirtle",
  "wartortle",
  "blastoise",
  "caterpie",
  "metapod",
  "butterfree",
  "weedle",
  "kakuna",
  "beedrill",
  "pidgey",
  "pidgeotto",
  "pidgeot",
  "rattata",
  "raticate",
  "spearow",
  "fearow",
  "ekans",
  "arbok",
  "pikachu",
  "raichu",
  "sandshrew",
  "sandslash",
  "nidoranf",
  "nidorina",
  "nidoqueen",
  "nidoranm",
  "nidorino",
  "nidoking",
  "clefairy",
  "clefable",
  "vulpix",
  "ninetales",
  "jigglypuff",
  "wigglytuff",
  "zubat",
  "golbat",
  "oddish",
  "gloom",
  "vileplume",
  "paras",
  "parasect",
  "venonat",
  "venomoth",
  "diglett",
  "dugtrio",
  "meowth",
  "persian",
  "psyduck",
  "golduck",
  "mankey",
  "primeape",
  "growlithe",
  "arcanine",
  "poliwag",
  "poliwhirl",
  "poliwrath",
  "abra",
  "kadabra",
  "alakazam",
  "machop",
  "machoke",
  "machamp",
  "bellsprout",
  "weepinbell",
  "victreebel",
  "tentacool",
  "tentacruel",
  "geodude",
  "graveler",
  "golem",
  "ponyta",
  "rapidash",
  "slowpoke",
  "slowbro",
  "magnemite",
  "magneton",
  "farfetch_d",
  "doduo",
  "dodrio",
  "seel",
  "dewgong",
  "grimer",
  "muk",
  "shellder",
  "cloyster",
  "gastly",
  "haunter",
  "gengar",
  "onix",
  "drowzee",
  "hypno",
  "krabby",
  "kingler",
  "voltorb",
  "electrode",
  "exeggcute",
  "exeggutor",
  "cubone",
  "marowak",
  "hitmonlee",
  "hitmonchan",
  "lickitung",
  "koffing",
  "weezing",
  "rhyhorn",
  "rhydon",
  "chansey",
  "tangela",
  "kangaskhan",
  "horsea",
  "seadra",
  "goldeen",
  "seaking",
  "staryu",
  "starmie",
  "mr_mime",
  "scyther",
  "jynx",
  "electabuzz",
  "magmar",
  "pinsir",
  "tauros",
  "magikarp",
  "gyarados",
  "lapras",
  "ditto",
  "eevee",
  "vaporeon",
  "jolteon",
  "flareon",
  "porygon",
  "omanyte",
  "omastar",
  "kabuto",
  "kabutops",
  "aerodactyl",
  "snorlax",
  "articuno",
  "zapdos",
  "moltres",
  "dratini",
  "dragonair",
  "dragonite",
  "mewtwo",
  "mew"
];
Map<String, Object?> _eventFingerprint(SourceEventDefinition event) => {
      'identity': event.identity.value,
      'sourceMapId': event.sourceMapId,
      'sourceEventId': event.sourceEventId,
      'sourceFileId': event.sourceFileId.value,
      'name': event.name,
      'x': event.x,
      'y': event.y,
      'locator': event.locator.toJson(),
      'quarantined': event.isQuarantined,
      'pages': [
        for (final page in event.pages)
          {
            'sourcePage': page.sourcePage.toJson(),
            'locator': page.locator.toJson(),
            'condition': page.condition.toJson(),
            'rawDataRef': page.rawDataRef?.toJson(),
            'body': [
              for (final node in page.body.nodes)
                node is SourcePokedexRewardProgramNode
                    ? node.toJson()
                    : {'kind': node.runtimeType.toString()}
            ],
            'graphic': page.graphic == null
                ? null
                : {
                    'tileId': page.graphic!.tileId,
                    'characterName': page.graphic!.characterName,
                    'hue': page.graphic!.hue,
                    'direction': page.graphic!.direction,
                    'pattern': page.graphic!.pattern,
                    'opacity': page.graphic!.opacity,
                    'blendType': page.graphic!.blendType,
                    'moveType': page.graphic!.moveType,
                    'moveSpeed': page.graphic!.moveSpeed,
                    'moveFrequency': page.graphic!.moveFrequency,
                    'walkAnime': page.graphic!.walkAnime,
                    'stepAnime': page.graphic!.stepAnime,
                    'directionFix': page.graphic!.directionFix,
                    'through': page.graphic!.through,
                    'alwaysOnTop': page.graphic!.alwaysOnTop,
                    'moveRouteNodeId': page.graphic!.moveRouteNodeId,
                  },
          }
      ],
    };
