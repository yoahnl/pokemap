# PSDK Parity Family Summary

Date: 2026-05-22
Worktree: `/Users/karim/.config/superpowers/worktrees/pokemonProject/psdk-phase-c-lot88-transform`

## Reading Rules

- `strict` means true PSDK parity marker: `ported` for methods, `fait` for Studio attacks.
- `executable` means the local engine can route the method: `ported + partial`.
- Current executable coverage is 100%: no `missing`, no `pas_fait`, no unknown Studio method.
- Family rows are a practical grouping by main blocker. Some PSDK methods have several blockers, so the blocker table is non-exclusive.

## Global

| Scope | Strict parity | Executable | Remaining strict work |
| --- | ---: | ---: | ---: |
| PSDK methods | 284 / 330 = 86.1% | 330 / 330 = 100% | 46 partial |
| Studio attacks | 640 / 728 = 87.9% | 728 / 728 = 100% | 88 partial |

## Strict Parity by Large Family

This family table is an approximate grouping for prioritization. The global
counts, blocker table and partial-method table below are regenerated from the
current audit and should be treated as authoritative.

| Family | Method parity | Attack parity | Main remaining reason |
| --- | ---: | ---: | --- |
| Core basic/status/stat | 5 / 5 = 100.0% | 172 / 324 = 53.1% | Many `s_basic` metadata riders still partial |
| Effects / volatiles / protections | 37 / 111 = 33.3% | 71 / 134 = 53.0% | Effect lifecycle, Substitute, volatiles |
| Abilities | 34 / 78 = 43.6% | 49 / 106 = 46.2% | Ability hooks and suppression edge cases |
| Items | 6 / 6 = 100.0% | 14 / 23 = 60.9% | Attack-level item branches still partial |
| Field / weather / terrain / rooms | 7 / 7 = 100.0% | 3 / 3 = 100.0% | No strict blocker in current grouping |
| KO / faint process | 2 / 3 = 66.7% | 3 / 4 = 75.0% | Faint callbacks and double-KO semantics |
| Damage / power / HP healing | 38 / 38 = 100.0% | 54 / 57 = 94.7% | A few attack-level special branches |
| History / action order / forced turns | 8 / 8 = 100.0% | 16 / 16 = 100.0% | No strict blocker in current grouping |
| Dedicated miscellaneous moves | 70 / 70 = 100.0% | 46 / 46 = 100.0% | No strict blocker in current grouping |
| Switch / phazing / position | 1 / 1 = 100.0% | 1 / 1 = 100.0% | No strict blocker in current grouping |
| Multi-target / doubles targeting | 2 / 2 = 100.0% | 2 / 2 = 100.0% | No strict blocker in current grouping |
| Status cures / status utility | 1 / 1 = 100.0% | 1 / 1 = 100.0% | No strict blocker in current grouping |

## Cross-Cutting Blockers

These are non-exclusive: one partial method can appear in several rows.

| Blocker | Partial methods affected | Share of remaining 46 partial methods |
| --- | ---: | ---: |
| Effects | 46 | 100.0% |
| Abilities | 19 | 41.3% |
| Damage handler | 14 | 30.4% |
| Items | 14 | 30.4% |
| Field | 4 | 8.7% |
| Multi-target targeting | 1 | 2.2% |

## High-Impact Partial Attack Families

| Battle method | Partial Studio attacks |
| --- | ---: |
| `s_basic` | 37 |
| `s_z_move` | 10 |
| `s_self_stat_z_move` | 2 |

## Estimate

For true 100% strict parity, remaining work is not 88 isolated lots. It should be grouped into roughly 15 to 19 large lots:

- effects lifecycle first;
- ability hooks second;
- item hooks third;
- then field, targeting, history/order, faint process, and strict attack-level cleanup.
