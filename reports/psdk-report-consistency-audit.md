# PSDK Report Consistency Audit

Date: 2026-05-23
Worktree: `/Users/karim/.config/superpowers/worktrees/pokemonProject/psdk-phase-c-lot88-transform`

## Files Audited

- `reports/psdk-attack-coverage.md`
- `reports/psdk-fight-parity-audit.json`
- `reports/psdk-fight-parity-audit.md`
- `reports/psdk-move-registry.md`

## Global Consistency

| Check | Result |
| --- | --- |
| All four files exist | OK |
| Attack coverage table rows | 728 |
| Audit JSON attack entries | 728 |
| Attack coverage vs audit JSON per move | OK, 0 mismatches |
| Registry method rows | 330 |
| Registry duplicate methods | 0 |
| Attack coverage duplicate attacks | 0 |
| Audit JSON duplicate moves | 0 |

## Metrics Confirmed

| Source | Metric | Value |
| --- | --- | ---: |
| `psdk-attack-coverage.md` | total attacks | 728 |
| `psdk-attack-coverage.md` | unique battle engine methods | 258 |
| `psdk-attack-coverage.md` | fait | 655 |
| `psdk-attack-coverage.md` | partiel | 73 |
| `psdk-attack-coverage.md` | pas_fait | 0 |
| `psdk-attack-coverage.md` | unknown_methods | 0 |
| `psdk-fight-parity-audit.json` | total attacks | 728 |
| `psdk-fight-parity-audit.json` | fait | 655 |
| `psdk-fight-parity-audit.json` | partiel | 73 |
| `psdk-fight-parity-audit.json` | pas_fait | 0 |
| `psdk-fight-parity-audit.json` | unknown methods | 0 |
| `psdk-move-registry.md` | ported methods | 301 |
| `psdk-move-registry.md` | partial methods | 29 |
| `psdk-move-registry.md` | missing methods | 0 |

## Important Interpretation

The files are internally coherent, but they do not all answer the same question.

- `psdk-move-registry.md` tracks registered PSDK battle methods.
- `psdk-attack-coverage.md` tracks individual Studio attacks, with stricter per-attack rules.
- `psdk-fight-parity-audit.json` is the structured version of the attack-level audit.
- `psdk-fight-parity-audit.md` is the human-readable version of that audit.

This means a method can be `ported` in the registry while one specific attack using that method remains `partiel` because the Studio attack has metadata, riders, item/ability branches, or effect hooks outside the strict supported slice.

## Cross-File Discrepancies To Keep In Mind

### Studio-Only / Generated Methods Not In PSDK Registry

These are present in Studio move data and handled by the coverage/audit layer, but absent from the 330 registered PSDK method matrix:

| Method | Attack count | Attacks |
| --- | ---: | --- |
| `s_z_move` | 10 | `catastropika`, `let_s_snuggle_forever`, `menacing_moonraze_maelstrom`, `oceanic_operetta`, `pulverizing_pancake`, `s10_000_000_volt_thunderbolt`, `searing_sunraze_smash`, `sinister_arrow_raid`, `soul_stealing_7_star_strike`, `stoked_sparksurfer` |
| `s_self_stat_z_move` | 2 | `clangorous_soulblaze`, `extreme_evoboost` |
| `s_genesis_supernova` | 1 | `genesis_supernova` |
| `s_guardian_of_alola` | 1 | `guardian_of_alola` |
| `s_hyperspace_hole` | 1 | `hyperspace_hole` |
| `s_light_that_burns_the_sky` | 1 | `light_that_burns_the_sky` |
| `s_malicious_moonsault` | 1 | `malicious_moonsault` |
| `s_splintered_stormshards` | 1 | `splintered_stormshards` |

These explain why `unknown_methods = 0` does not mean every Studio method is a registered Ruby PSDK method. It means the audit tool knows how to classify every Studio method.

### Registry Ported, Attack Still Partiel

There are now `38` attacks that use methods marked `ported` in the registry, but the attack-level audit downgrades the attack to `partiel`.
Representative examples:

| Attack | Method | Registry status | Attack status |
| --- | --- | --- | --- |
| `acid_downpour` | `s_basic` | ported | partiel |
| `acid_downpour2` | `s_basic` | ported | partiel |
| `breakneck_blitz` | `s_basic` | ported | partiel |
| `oblivion_wing` | `s_absorb` | ported | partiel |

This is expected if the move method's core local behavior is ported but some attack-specific PSDK hooks remain outside strict parity.

## Partial Reasons From Audit JSON

| Reason | Count |
| --- | ---: |
| `ported_method_metadata_outside_strict_slice` | 39 |
| `method_partial` | 35 |

So the remaining `73` partial attacks split into:

- `38` attacks whose method is considered ported, but metadata/riders are outside strict coverage;
- `35` attacks whose method itself is still partial.

## Conclusion

The headline numbers are reliable:

- attack strict parity: `655 / 728 = 90.0%`;
- method strict parity: `301 / 330 = 91.2%`;
- executable coverage: `100%` for known Studio attacks and registered PSDK methods.

But the previous family summary must be read carefully: method parity and attack parity are different layers. The remaining work is mostly strict hook parity, not basic method routing.
