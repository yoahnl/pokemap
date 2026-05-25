# PSDK Fight 100 Percent Acceptance Gate

Date: 2026-05-25

## Purpose

This document defines the mechanical acceptance gate for claiming 100 percent
Pokemon SDK battle parity. The gate is intentionally stricter than the
non-regression gate and must stay green before claiming final measured parity.

## Command

```bash
cd packages/map_battle
dart run tool/psdk_fight_parity_audit.dart --final-gate --goldens test/fixtures/psdk_golden
```

## Requirements

- `728 / 728` Studio attacks must be strict `fait`, or explicitly approved as
  out of scope.
- `330 / 330` PSDK battle methods must be `ported`, or explicitly approved as
  out of scope.
- `482 / 482` PSDK effect classes must be `ported`, or explicitly approved as
  out of scope.
- Unknown battle methods must remain `0`.
- Runtime bridge parity must be measured and every unsupported playable move
  must be explained by diagnostics.
- At least one golden fixture must exist. More fixtures should be added per
  representative PSDK family before the gate can be considered meaningful.

## Current Status

The gate now passes on the measured PSDK fight parity axes:

- attacks complete: `728 / 728`
- methods complete: `330 / 330`
- effects complete: `482 / 482`
- unknown methods: `0`
- runtime bridge: `28` sampled runtime moves, `20` bridgeable,
  `8` rejected with diagnostics, `0` unexplained rejections

The runtime bridge remains intentionally measured as a sampled integration
surface: unsupported playable host rows are accepted only because each rejected
row has an explicit diagnostic reason.
