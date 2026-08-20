/// Registre des Golden Gates par domaine bêta — BETA-SYS-007.
///
/// Le ticket demande d'« assembler les Golden Gates des dix domaines dans une
/// certification hermétique ». Mesuré le 2026-08-20 : les gates existent mais
/// sont éparpillées dans quatre paquets, rien ne déclare quel domaine est
/// couvert par quoi, et quatre gates de domaine n'existent pas encore
/// (rencontres, progression post-combat, Party/PC, économie complète).
///
/// Ce registre est l'assemblage : chaque domaine du cockpit pointe soit ses
/// gates réelles — des FICHIERS DE TEST dont un garde vérifie l'existence sur
/// disque — soit une dette nommée, rattachée au ticket qui la portera. Quand une
/// gate manquante livre, le test de ce registre échoue jusqu'au reclassement,
/// exactement comme le catalogue de composition de la gate de jouabilité.
///
/// La certification produit reste NO-GO tant qu'une dette subsiste : le verdict
/// est calculé depuis ce registre, pas déclaré.
library;

/// Couverture d'un domaine par ses Golden Gates.
enum DomainGateCoverage {
  /// Le domaine a une ou plusieurs gates réelles qui ferment son parcours.
  gated,

  /// Des gates réelles existent mais un morceau nommé du parcours manque.
  partial,

  /// Aucune gate : la dette est portée par un ticket nommé.
  pendingGate,
}

/// Un domaine bêta et l'état de ses Golden Gates.
class ProductCertificationDomainGate {
  const ProductCertificationDomainGate({
    required this.domain,
    required this.coverage,
    required this.gateTestPaths,
    required this.rationale,
    this.pendingTicket,
  });

  /// Nom stable du domaine, aligné sur les familles du cockpit.
  final String domain;

  final DomainGateCoverage coverage;

  /// Chemins des gates, relatifs à la racine du dépôt.
  ///
  /// Chaque chemin est vérifié sur disque par le test du registre : une gate
  /// fantôme est pire qu'une dette, elle a l'air de couvrir.
  final List<String> gateTestPaths;

  /// Pourquoi cette couverture, et quoi ne pas casser.
  final String rationale;

  /// Ticket qui portera la gate manquante, pour `partial` et `pendingGate`.
  final String? pendingTicket;
}

/// Le registre, trié par domaine.
const List<ProductCertificationDomainGate> productCertificationDomainGates =
    <ProductCertificationDomainGate>[
  ProductCertificationDomainGate(
    domain: 'battle',
    coverage: DomainGateCoverage.gated,
    gateTestPaths: <String>[
      'packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart',
      'packages/map_runtime/test/runtime_battle_ui_matches_kernel_test.dart',
      'packages/map_battle/test/battle_terminal_invariants_test.dart',
    ],
    rationale: 'BETA-BAT-008. Sept scénarios terminaux hermétiques, identité '
        'UI = kernel sur les quatre issues, write-back unique. La capture y '
        'transporte l’individu rencontré (BETA-ENC-002).',
  ),
  ProductCertificationDomainGate(
    domain: 'cinematics',
    coverage: DomainGateCoverage.gated,
    gateTestPaths: <String>[
      'tools/pokemap_product_certification/test/cinematic_v2_final_certification_cli_test.dart',
      'tools/pokemap_product_certification/test/cinematic_v2_final_repository_gate_test.dart',
      'tools/pokemap_product_certification/test/cinematic_v2_zero_legacy_gate_test.dart',
    ],
    rationale: 'Famille 1, close : certification CIN-V2 finale, gate de dépôt, '
        'et zéro-legacy.',
  ),
  ProductCertificationDomainGate(
    domain: 'editorPerformance',
    coverage: DomainGateCoverage.gated,
    gateTestPaths: <String>[
      '.github/workflows/beta_perf_009_certification.yml',
      'tools/pokemap_product_certification/test/certification_budgets_test.dart',
    ],
    rationale: 'BETA-PERF-009 : gate de soak mémoire et non-régression, plus '
        'les budgets de la phase 8. La gate vit en CI parce qu’elle mesure des '
        'durées réelles.',
  ),
  ProductCertificationDomainGate(
    domain: 'encounterCapture',
    coverage: DomainGateCoverage.gated,
    gateTestPaths: <String>[
      'packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart',
      'tools/pokemap_product_certification/test/golden_encounter_capture_gate_test.dart',
    ],
    rationale: 'BETA-ENC-006. Depuis un package installé seul : un pas dans '
        'l’herbe déclenche la rencontre déterminée par les données, la Poké '
        'Ball 1/1 échoue (deux secousses ENC-005), la fuite ramène à '
        'l’overworld, la Ball 17/1 capture en garantie mathématique — vers la '
        'party quand il reste une place, vers le PC quand elle est pleine — '
        'et l’individu, le Pokédex et la position rechargent à l’identique.',
  ),
  ProductCertificationDomainGate(
    domain: 'itemsEconomy',
    coverage: DomainGateCoverage.gated,
    gateTestPaths: <String>[
      'tools/pokemap_product_certification/test/item_system_certification_test.dart',
      'tools/pokemap_product_certification/test/item_system_transport_evidence_collector_test.dart',
      'tools/pokemap_product_certification/test/golden_economy_town_gate_test.dart',
    ],
    rationale: 'BETA-ITM-008. Depuis un package installé seul : ramassage par '
        'événement V2 oneShot (non rejouable après reload), récompense de '
        'victoire portant argent ET objet, soin au centre par le service '
        'monde réel, achat et revente aux montants exacts, CT compatible '
        'apprise et objet tenu à effet porté équipé par le canal pause — le '
        'tout rechargé à l’identique. Un export refusant un article de '
        'boutique inconnu ferme la gate du catalogue invalide. La '
        'certification L0–L6 exécutable (36 paires action × transport, '
        'BETA-ITM-007) reste la preuve de parité des transports.',
  ),
  ProductCertificationDomainGate(
    domain: 'partyStorage',
    coverage: DomainGateCoverage.gated,
    gateTestPaths: <String>[
      'tools/pokemap_product_certification/test/golden_party_storage_gate_test.dart',
    ],
    rationale: 'BETA-PTY-005. Depuis un package installé seul : nouvelle '
        'partie à deux membres, réordonnancement pause, dépôt, retrait, fiche '
        'PC consultée, sauvegarde, reprise — et le roster recharge '
        'structurellement identique, party et box, identités comprises.',
  ),
  ProductCertificationDomainGate(
    domain: 'pokemonData',
    coverage: DomainGateCoverage.gated,
    gateTestPaths: <String>[
      'packages/map_core/test/pokemon_catalog_coherence_validator_test.dart',
      'packages/map_editor/test/import_pokemon_catalog_json_use_case_test.dart',
    ],
    rationale: 'Famille 4, PASS certifié (PR #8, CI verte) : cohérence des '
        'catalogues et import. La cohérence est composée dans le verdict de '
        'jouabilité depuis BETA-SYS-005.',
  ),
  ProductCertificationDomainGate(
    domain: 'postBattleProgression',
    coverage: DomainGateCoverage.pendingGate,
    gateTestPaths: <String>[],
    rationale: 'XP et niveaux sont certifiés unitairement (BETA-PRG-001/002) '
        'mais aucune gate ne ferme victoire ET défaite avec level-up, '
        'apprentissage, évolution, blackout et reprise.',
    pendingTicket: 'BETA-PRG-006',
  ),
  ProductCertificationDomainGate(
    domain: 'startupPersistence',
    coverage: DomainGateCoverage.gated,
    gateTestPaths: <String>[
      'tools/pokemap_product_certification/test/golden_launch_save_resume_gate_test.dart',
      'tools/pokemap_product_certification/test/offline_save_continue_test.dart',
      'tools/pokemap_product_certification/test/build_neutral_package_artifact_test.dart',
    ],
    rationale: 'Famille 2, close : export → install → launch → save → resume '
        'sur package neutre, hors ligne compris. C’est le « full journey » du '
        'ticket.',
  ),
  ProductCertificationDomainGate(
    domain: 'trainers',
    coverage: DomainGateCoverage.gated,
    gateTestPaths: <String>[
      'packages/map_runtime/test/trainer_spot_sequence_test.dart',
      'tools/pokemap_product_certification/test/golden_trainer_arena_gate_test.dart',
    ],
    rationale: 'BETA-TRN-005. Depuis un package installé seul : la ligne de '
        'vue du boss déclenche, la défaite du premier assaut est déterminée '
        'par les données, le whiteout complet récupère (respawn, soins, '
        'pénalité d’argent), le rival récurrent se rebat deux fois — '
        'dialogues pré/victoire des templates, réarmement par sortie de '
        'ligne de vue, potions par le canal pause — et la victoire du boss '
        'applique badge, flag, Surf et argent exactement une fois, le tout '
        'rechargé identique. L’hydratation durcie des équipes est BETA-TRN-003.',
  ),
  ProductCertificationDomainGate(
    domain: 'transverseSystems',
    coverage: DomainGateCoverage.gated,
    gateTestPaths: <String>[
      'packages/map_core/test/beta_playability_composition_test.dart',
      'packages/map_core/test/gameplay_roadmap_dashboard_cli_test.dart',
      'packages/map_runtime/test/runtime_failure_taxonomy_test.dart',
      'tools/pokemap_product_certification/test/product_certification_receipt_test.dart',
      'tools/pokemap_product_certification/test/platform_certification_repository_gate_test.dart',
    ],
    rationale: 'BETA-SYS-005/006/008 : composition de la gate de jouabilité, '
        'dashboard FG sur layout canonique, taxonomie des défaillances et '
        'non-fuite, receipt produit déterministe et expurgé, gate plateformes.',
  ),
  ProductCertificationDomainGate(
    domain: 'worldNarrative',
    coverage: DomainGateCoverage.gated,
    gateTestPaths: <String>[
      'packages/map_runtime/test/p3_scenario_runtime_golden_path_test.dart',
      'packages/map_runtime/test/p5_beta_runtime_smoke_test.dart',
      'packages/map_runtime/test/p5_gameplay_save_load_beta_roundtrip_test.dart',
    ],
    rationale: 'Famille 3, close : golden path scénario, smoke bêta et '
        'aller-retour sauvegarde du gameplay monde.',
  ),
];

/// Verdict d'assemblage : GO seulement quand plus aucune dette ne subsiste.
///
/// Calculé, pas déclaré — c'est ce qui empêche de prononcer la certification
/// produit tant que PRG-006 n'a pas livré sa gate.
bool get productCertificationDomainGatesComplete =>
    productCertificationDomainGates.every(
      (gate) => gate.coverage == DomainGateCoverage.gated,
    );
