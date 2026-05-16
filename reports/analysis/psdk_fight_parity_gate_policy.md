# PSDK Fight Parity Gate Policy

## Purpose

This policy documents the Lot 02 non-regression gate for Pokemon SDK fight parity. The gate does not claim 100% parity. It prevents accidental loss of the measured baseline while later lots promote partial behavior to strict parity.

## Baseline

Baseline source:

- `reports/analysis/psdk_fight_parity_audit_2026-05-16.md`
- `reports/analysis/psdk_fight_100_percent_lot_plan_2026-05-16.md`
- `packages/map_battle/tool/psdk_fight_parity_audit.dart`

Current baseline:

| Metric | Minimum / Maximum |
| --- | ---: |
| Unknown methods | maximum `0` |
| Strict Studio attacks | minimum `33` |
| Strict PSDK battle methods | minimum `25` |
| Known-or-partial PSDK effects | minimum `25` |

`Known-or-partial PSDK effects` is currently `ported + partial`. At the time this gate was introduced, effects were `0 ported + 25 partial`.

## Command

Run from `packages/map_battle`:

```bash
dart run tool/psdk_fight_parity_audit.dart --gate --json /tmp/psdk-fight-audit.json --markdown /tmp/psdk-fight-audit.md
```

Expected success output:

```text
PSDK parity gate passed.
PSDK fight parity audit: 33/728 attacks strict, 330 manifest methods, 482 effects.
```

## Failure Semantics

The gate fails if any of these conditions are true:

- `unknown_methods > 0`
- `strict_attacks < 33`
- `strict_methods < 25`
- `known_or_partial_effects < 25`

Failure messages are intentionally explicit, for example:

```text
PSDK parity gate failed:
- unknown_methods=1 exceeds maximum 0
- strict_attacks=32 is below minimum 33
```

## How to Update the Gate

Only update thresholds after a lot has:

1. added behavior tests proving the promoted parity;
2. updated the manifest or effect status honestly;
3. regenerated the audit and confirmed the new number;
4. run `cd packages/map_battle && dart test --reporter compact`;
5. updated this policy with the new baseline.

Do not lower thresholds unless intentionally reverting a lot. If a revert is necessary, the report should name the reverted commit and reason.

## Non-Goals

This gate does not measure runtime bridge parity yet. Runtime bridge diagnostics are planned by Lot 04.

This gate does not prove 100% Pokemon SDK parity. It is a guardrail to keep future work from sliding backward.
